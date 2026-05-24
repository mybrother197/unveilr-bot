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
UNVEILR_PATH = Path(__file__).resolve().parent / "core" / "hi.luau"
LAUFUSCATOR_PATH = Path(__file__).resolve().parent / "core" / "laufuscator.lua"
TEMP_DIR = Path(__file__).resolve().parent / "temp"
TEMP_DIR.mkdir(exist_ok=True)

class MyClient(discord.Client):
    def __init__(self):
        intents = discord.Intents.default() 
        super().__init__(intents=intents)
        self.tree = app_commands.CommandTree(self)

    async def setup_hook(self):
        await self.tree.sync()
        print(f"Synced slash commands.")

client = MyClient()

@client.event
async def on_ready():
    print(f'Logged in as {client.user} (ID: {client.user.id})')
    print('------')

async def run_lune(logic_path, input_code_path, output_code_path):
    lune_cmd = shutil.which('lune')
    if not lune_cmd:
        local_lune = Path(__file__).resolve().parent / ('lune.exe' if os.name == 'nt' else 'lune')
        if local_lune.exists():
            lune_cmd = str(local_lune)
        else:
            lune_cmd = 'lune'
    
    try:
        process = await asyncio.create_subprocess_exec(
            lune_cmd, 'run', str(logic_path), str(input_code_path), f"--outfile={str(output_code_path)}",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=30.0)
            return process.returncode, stdout, stderr
        except asyncio.TimeoutError:
            process.kill()
            return -1, b"", b"Analysis timed out! The script took too long to analyze (infinite loop or too complex)."
            
    except Exception as e:
        return -1, b"", str(e).encode()

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

@client.tree.command(name="unveil", description="오퓨스케이트된 루아 코드를 분석합니다.")
@app_commands.describe(file="분석할 파일", code="분석할 코드 직접 입력")
async def unveil(interaction: discord.Interaction, file: Optional[discord.Attachment] = None, code: Optional[str] = None):
    if not any([file, code]):
        await interaction.response.send_message("파일 또는 코드를 제공해주세요!", ephemeral=True)
        return

    await interaction.response.defer(thinking=True)
    request_id = interaction.id
    input_path = TEMP_DIR / f"in_{request_id}.lua"
    output_path = TEMP_DIR / f"out_{request_id}.lua"

    try:
        success = await get_content(file, code, input_path)
        if success is not True:
            await interaction.followup.send(f"입력값 처리 실패: {success}")
            return

        ret_code, stdout, stderr = await run_lune(UNVEILR_PATH, input_path, output_path)

        if ret_code == 0 and output_path.exists():
            file_lua = discord.File(output_path, filename="unveiled.lua")
            file_txt = discord.File(output_path, filename="unveiled.txt")
            await interaction.followup.send("분석 완료!", files=[file_lua, file_txt])
        else:
            err_msg = stderr.decode('utf-8', errors='ignore').strip()
            out_msg = stdout.decode('utf-8', errors='ignore').strip()
            
            combined_err = f"코드: {ret_code}\n"
            if err_msg: combined_err += f"STDERR:\n```\n{err_msg[-400:]}\n```\n"
            if out_msg: combined_err += f"STDOUT:\n```\n{out_msg[-400:]}\n```"
            
            if not err_msg and not out_msg: combined_err += "원인 불명의 중단 (Lune 에러 권한/충돌일 수 있음)"

            await interaction.followup.send(f"분석 실패.\n{combined_err}")
    finally:
        if input_path.exists(): input_path.unlink()
        if output_path.exists(): output_path.unlink()

def get_lua54_cmd():
    """lua54.exe 경로 탐색: 봇 폴더 우선, 없으면 PATH에서 검색"""
    local_lua = Path(__file__).resolve().parent / ('lua54.exe' if os.name == 'nt' else 'lua54')
    if local_lua.exists():
        return str(local_lua)
    found = shutil.which('lua54') or shutil.which('lua5.4') or shutil.which('lua')
    return found or 'lua54'

@client.tree.command(name="obfuscate", description="루아 코드를 Laufuscator로 난독화합니다.")
@app_commands.describe(file="난독화할 .lua 파일", code="난독화할 코드 직접 입력")
async def obfuscate(interaction: discord.Interaction, file: Optional[discord.Attachment] = None, code: Optional[str] = None):
    if not any([file, code]):
        await interaction.response.send_message("파일 또는 코드를 제공해주세요!", ephemeral=True)
        return

    await interaction.response.defer(thinking=True)
    request_id = interaction.id
    input_path  = TEMP_DIR / f"obf_in_{request_id}.lua"
    output_path = TEMP_DIR / f"obf_out_{request_id}.lua"

    try:
        success = await get_content(file, code, input_path)
        if success is not True:
            await interaction.followup.send(f"입력값 처리 실패: {success}")
            return

        lua_cmd = get_lua54_cmd()
        # --quiet 플래그로 배너 출력 억제
        process = await asyncio.create_subprocess_exec(
            lua_cmd,
            str(LAUFUSCATOR_PATH),
            str(input_path),
            str(output_path),
            '--quiet',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=60.0)
            ret_code = process.returncode
        except asyncio.TimeoutError:
            process.kill()
            ret_code, stdout, stderr = -1, b"", b"Obfuscation timed out! (60s)"

        if ret_code == 0 and output_path.exists() and output_path.stat().st_size > 0:
            orig_size  = input_path.stat().st_size if input_path.exists() else 0
            obf_size   = output_path.stat().st_size
            ratio      = obf_size / orig_size if orig_size else 0
            summary    = (
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
            if not err_msg and not out_msg: combined += "원인 불명 (출력 없음)"
            await interaction.followup.send(combined)
    finally:
        if input_path.exists():  input_path.unlink(missing_ok=True)
        if output_path.exists(): output_path.unlink(missing_ok=True)

if __name__ == "__main__":
    if not TOKEN:
        print("에러: .env 파일에 DISCORD_TOKEN을 설정해주세요.")
    else:
        client.run(TOKEN)
