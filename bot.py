import discord
from discord import app_commands
import os
import subprocess
import aiohttp
import asyncio
import shutil
from dotenv import load_dotenv
from pathlib import Path
from typing import Optional

# Load .env
env_path = Path(__file__).resolve().parent / '.env'
load_dotenv(dotenv_path=env_path)

TOKEN = os.getenv('DISCORD_TOKEN')
UNVEILR_PATH    = Path(__file__).resolve().parent / "core" / "hi.luau"
LAUFUSCATOR_PATH = Path(__file__).resolve().parent / "core" / "laufuscator.lua"
TEMP_DIR = Path(__file__).resolve().parent / "temp"
TEMP_DIR.mkdir(exist_ok=True)

# ──────────────────────────────────────────────
# 실행파일 탐색 헬퍼
# ──────────────────────────────────────────────

def get_lune_cmd():
    """lune 실행파일 탐색 (PATH → 로컬 바이너리)"""
    found = shutil.which('lune')
    if found:
        return found
    local = Path(__file__).resolve().parent / ('lune.exe' if os.name == 'nt' else 'lune')
    if local.exists():
        return str(local)
    return None  # 없으면 None 반환

def get_lua_cmd():
    """Lua 실행파일 탐색 — Termux/Linux/Windows 전부 지원
    우선순위: lua54(로컬) → lua5.4 → lua54 → lua5.3 → lua
    """
    # Windows 전용 로컬 바이너리
    if os.name == 'nt':
        local = Path(__file__).resolve().parent / 'lua54.exe'
        if local.exists():
            return str(local)

    # PATH에서 순서대로 탐색
    for name in ('lua5.4', 'lua54', 'lua5.3', 'lua53', 'lua'):
        found = shutil.which(name)
        if found:
            return found

    return None  # 없으면 None

# ──────────────────────────────────────────────
# Discord 클라이언트
# ──────────────────────────────────────────────

class MyClient(discord.Client):
    def __init__(self):
        intents = discord.Intents.default()
        super().__init__(intents=intents)
        self.tree = app_commands.CommandTree(self)

    async def setup_hook(self):
        await self.tree.sync()
        print("Synced slash commands.")

client = MyClient()

@client.event
async def on_ready():
    print(f'Logged in as {client.user} (ID: {client.user.id})')
    print('------')
    lune = get_lune_cmd()
    lua  = get_lua_cmd()
    print(f'  lune : {lune or "NOT FOUND"}')
    print(f'  lua  : {lua  or "NOT FOUND"}')

# ──────────────────────────────────────────────
# 공통 유틸리티
# ──────────────────────────────────────────────

async def get_content(file: Optional[discord.Attachment], code: Optional[str], input_path: Path):
    connector = aiohttp.TCPConnector(ssl=False)
    async with aiohttp.ClientSession(connector=connector) as session:
        if file:
            async with session.get(file.url) as resp:
                if resp.status == 200:
                    with open(input_path, 'wb') as f:
                        f.write(await resp.read())
                    return True
        elif code:
            with open(input_path, 'w', encoding='utf-8') as f:
                f.write(code)
            return True
    return False

async def run_subprocess(cmd: list, timeout: float = 45.0):
    """서브프로세스 실행 + 타임아웃 처리. 항상 (returncode, stdout, stderr) 반환."""
    try:
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=timeout)
            return process.returncode, stdout, stderr
        except asyncio.TimeoutError:
            try:
                process.kill()
            except Exception:
                pass
            return -1, b"", f"시간 초과 ({timeout:.0f}s)".encode()
    except FileNotFoundError as e:
        return -2, b"", f"실행파일을 찾을 수 없습니다: {e}".encode()
    except Exception as e:
        return -3, b"", f"실행 오류: {e}".encode()

# ──────────────────────────────────────────────
# /unveil — Lua 난독화 해제
# ──────────────────────────────────────────────

@client.tree.command(name="unveil", description="오퓨스케이트된 루아 코드를 분석합니다.")
@app_commands.describe(file="분석할 파일", code="분석할 코드 직접 입력")
async def unveil(interaction: discord.Interaction,
                 file: Optional[discord.Attachment] = None,
                 code: Optional[str] = None):
    if not any([file, code]):
        await interaction.response.send_message("파일 또는 코드를 제공해주세요!", ephemeral=True)
        return

    await interaction.response.defer(thinking=True)
    request_id = interaction.id
    input_path  = TEMP_DIR / f"in_{request_id}.lua"
    output_path = TEMP_DIR / f"out_{request_id}.lua"

    try:
        # lune 탐색
        lune_cmd = get_lune_cmd()
        if not lune_cmd:
            await interaction.followup.send(
                "❌ **lune 런타임을 찾을 수 없습니다.**\n"
                "Termux: `pkg install lune` 또는 바이너리를 봇 폴더에 넣어주세요."
            )
            return

        success = await get_content(file, code, input_path)
        if not success:
            await interaction.followup.send("입력값 처리 실패.")
            return

        ret_code, stdout, stderr = await run_subprocess(
            [lune_cmd, 'run', str(UNVEILR_PATH), str(input_path),
             f"--outfile={str(output_path)}"],
            timeout=30.0
        )

        if ret_code == 0 and output_path.exists():
            file_lua = discord.File(output_path, filename="unveiled.lua")
            file_txt = discord.File(output_path, filename="unveiled.txt")
            await interaction.followup.send("분석 완료!", files=[file_lua, file_txt])
        else:
            err_msg = stderr.decode('utf-8', errors='ignore').strip()
            out_msg = stdout.decode('utf-8', errors='ignore').strip()
            combined = f"분석 실패 (코드: {ret_code})\n"
            if err_msg: combined += f"STDERR:\n```\n{err_msg[-400:]}\n```\n"
            if out_msg: combined += f"STDOUT:\n```\n{out_msg[-400:]}\n```"
            if not err_msg and not out_msg:
                combined += "원인 불명 (출력 없음)"
            await interaction.followup.send(combined)

    except Exception as e:
        # 최상위 안전망 — 이게 없으면 "생각중" 무한대기
        try:
            await interaction.followup.send(f"❌ 예상치 못한 오류: ```{e}```")
        except Exception:
            pass
    finally:
        for p in (input_path, output_path):
            try:
                if p.exists(): p.unlink()
            except Exception:
                pass

# ──────────────────────────────────────────────
# /obfuscate — Laufuscator 난독화
# ──────────────────────────────────────────────

@client.tree.command(name="obfuscate", description="루아 코드를 Laufuscator로 난독화합니다.")
@app_commands.describe(file="난독화할 .lua 파일", code="난독화할 코드 직접 입력")
async def obfuscate(interaction: discord.Interaction,
                    file: Optional[discord.Attachment] = None,
                    code: Optional[str] = None):
    if not any([file, code]):
        await interaction.response.send_message("파일 또는 코드를 제공해주세요!", ephemeral=True)
        return

    await interaction.response.defer(thinking=True)
    request_id  = interaction.id
    input_path  = TEMP_DIR / f"obf_in_{request_id}.lua"
    output_path = TEMP_DIR / f"obf_out_{request_id}.lua"

    try:
        # lua 탐색
        lua_cmd = get_lua_cmd()
        if not lua_cmd:
            await interaction.followup.send(
                "❌ **Lua 인터프리터를 찾을 수 없습니다.**\n"
                "Termux: `pkg install lua54` 후 봇을 재시작해주세요."
            )
            return

        success = await get_content(file, code, input_path)
        if not success:
            await interaction.followup.send("입력값 처리 실패.")
            return

        ret_code, stdout, stderr = await run_subprocess(
            [lua_cmd, str(LAUFUSCATOR_PATH), str(input_path), str(output_path), '--quiet'],
            timeout=60.0
        )

        if ret_code == 0 and output_path.exists() and output_path.stat().st_size > 0:
            orig_size = input_path.stat().st_size if input_path.exists() else 0
            obf_size  = output_path.stat().st_size
            ratio     = obf_size / orig_size if orig_size else 0
            summary   = (
                f"✅ **Laufuscator 난독화 완료!**\n"
                f"> 원본: `{orig_size:,}` bytes → 난독화: `{obf_size:,}` bytes (x{ratio:.1f})"
            )
            file_lua = discord.File(output_path, filename="obfuscated.lua")
            await interaction.followup.send(summary, file=file_lua)
        else:
            err_msg = stderr.decode('utf-8', errors='ignore').strip()
            out_msg = stdout.decode('utf-8', errors='ignore').strip()
            combined = f"❌ **난독화 실패** (코드: {ret_code})\n"
            if err_msg: combined += f"```\n{err_msg[-800:]}\n```"
            if out_msg: combined += f"```\n{out_msg[-400:]}\n```"
            if not err_msg and not out_msg:
                combined += "원인 불명 (출력 없음)"
            await interaction.followup.send(combined)

    except Exception as e:
        # 최상위 안전망 — 이게 없으면 "생각중" 무한대기
        try:
            await interaction.followup.send(f"❌ 예상치 못한 오류: ```{e}```")
        except Exception:
            pass
    finally:
        for p in (input_path, output_path):
            try:
                if p.exists(): p.unlink()
            except Exception:
                pass

# ──────────────────────────────────────────────

if __name__ == "__main__":
    if not TOKEN:
        print("에러: .env 파일에 DISCORD_TOKEN을 설정해주세요.")
    else:
        client.run(TOKEN)
