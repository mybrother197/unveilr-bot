import discord
from discord import app_commands
import os
import subprocess
import aiohttp
import asyncio
import shutil
from dotenv import load_dotenv
from pathlib import Path

# Load .env from the script's directory
env_path = Path(__file__).resolve().parent / '.env'
load_dotenv(dotenv_path=env_path)

TOKEN = os.getenv('DISCORD_TOKEN')
# Core logic is now inside the 'core' folder in the bot directory
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

@client.tree.command(name="unveil", description="오퓨스케이트된 루아 스크립트를 분석합니다.")
@app_commands.describe(file="분석할 .lua 파일을 업로드하세요.")
async def unveil(interaction: discord.Interaction, file: discord.Attachment):
    if not file.filename.endswith('.lua'):
        await interaction.response.send_message("`.lua` 파일만 지원합니다.", ephemeral=True)
        return

    await interaction.response.defer(thinking=True)

    request_id = interaction.id
    input_path = TEMP_DIR / f"input_{request_id}.lua"
    output_path = TEMP_DIR / f"output_{request_id}.lua"

    try:
        # Download attachment
        async with aiohttp.ClientSession() as session:
            async with session.get(file.url) as resp:
                if resp.status == 200:
                    with open(input_path, 'wb') as f:
                        f.write(await resp.read())
                else:
                    await interaction.followup.send(f"파일 다운로드 실패 (Status: {resp.status})")
                    return

        # Improved Lune lookup
        lune_cmd = shutil.which('lune')
        if not lune_cmd:
            # Check local directory or root
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
            discord_file = discord.File(output_path, filename="unveiled.lua")
            await interaction.followup.send("분석 완료!", file=discord_file)
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
