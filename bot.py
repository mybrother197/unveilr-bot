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

# Load .env from the script's directory
env_path = Path(__file__).resolve().parent / '.env'
load_dotenv(dotenv_path=env_path)

TOKEN = os.getenv('DISCORD_TOKEN')
UNVEILR_PATH = Path(__file__).resolve().parent / "core" / "hi.luau"
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

@client.tree.command(name="unveil", description="오퓨스케이트된 루아 코드를 분석합니다 (파일 또는 텍스트 입력 가능).")
@app_commands.describe(file="분석할 .lua 또는 .txt 파일을 업로드하세요.", code="분석할 코드를 직접 입력하거나 붙여넣으세요.")
async def unveil(interaction: discord.Interaction, file: Optional[discord.Attachment] = None, code: Optional[str] = None):
    # Check if at least one input is provided
    if not file and not code:
        await interaction.response.send_message("파일을 업로드하거나 코드를 직접 입력해주세요!", ephemeral=True)
        return

    await interaction.response.defer(thinking=True)

    request_id = interaction.id
    input_path = TEMP_DIR / f"input_{request_id}.lua"
    output_path = TEMP_DIR / f"output_{request_id}.lua"

    try:
        # Source 1: If file is provided
        if file:
            if not (file.filename.endswith('.lua') or file.filename.endswith('.txt')):
                await interaction.followup.send("`.lua` 또는 `.txt` 파일만 지원합니다.")
                return
            
            async with aiohttp.ClientSession() as session:
                async with session.get(file.url) as resp:
                    if resp.status == 200:
                        with open(input_path, 'wb') as f:
                            f.write(await resp.read())
                    else:
                        await interaction.followup.send(f"파일 다운로드 실패 (Status: {resp.status})")
                        return
        
        # Source 2: If code string is provided (overwrites file source if both exist)
        elif code:
            with open(input_path, 'w', encoding='utf-8') as f:
                f.write(code)

        # Improved Lune lookup
        lune_cmd = shutil.which('lune')
        if not lune_cmd:
            local_lune = Path(__file__).resolve().parent / ('lune.exe' if os.name == 'nt' else 'lune')
            if local_lune.exists():
                lune_cmd = str(local_lune)
            else:
                lune_cmd = 'lune'

        if not UNVEILR_PATH.exists():
            await interaction.followup.send("오류: 분석 도구 핵심 파일을 찾을 수 없습니다. (core/hi.luau)")
            return

        process = await asyncio.create_subprocess_exec(
            lune_cmd, 'run', str(UNVEILR_PATH), str(input_path), f'--outfile={str(output_path)}',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        stdout, stderr = await process.communicate()

        if process.returncode == 0 and output_path.exists():
            # Send result as .txt file as requested
            discord_file = discord.File(output_path, filename="unveiled_result.txt")
            await interaction.followup.send("분석 완료! 결과물을 .txt 파일로 보내드립니다.", file=discord_file)
        else:
            out_msg = stdout.decode('utf-8', errors='ignore')
            err_msg = stderr.decode('utf-8', errors='ignore')
            await interaction.followup.send(f"분석 도중 오류가 발생했습니다.\n코드: {process.returncode}\n출력: ```{out_msg[-500:]}```\n성적: ```{err_msg[-500:]}```")

    except Exception as e:
        await interaction.followup.send(f"예상치 못한 오류 발생: {str(e)}")
    finally:
        # Cleanup
        if input_path.exists(): input_path.unlink()
        if output_path.exists(): output_path.unlink()

if __name__ == "__main__":
    if not TOKEN:
        print("에러: .env 파일에 DISCORD_TOKEN을 설정해주세요.")
    else:
        client.run(TOKEN)
