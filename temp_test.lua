--[[ Prometheus VM v6.0 | Anti-Static Analysis ]]
local _VMsh7O2jnF = (function(...)
    local _0x_junkbfAvJYzp = 5399; _0x_junkbfAvJYzp = _0x_junkbfAvJYzp + 13; local _0x_junkMr6r2rww = 8103; _0x_junkMr6r2rww = _0x_junkMr6r2rww + 47; local _0x_junkKrpDg4ff = 3160; _0x_junkKrpDg4ff = _0x_junkKrpDg4ff + 53; local _0x_junkP2cbIQjv = 1225; _0x_junkP2cbIQjv = _0x_junkP2cbIQjv + 59; local _0x_junkVW7rUjCT = 9256; _0x_junkVW7rUjCT = _0x_junkVW7rUjCT + 24; local _0x_junkLMPXoHE4 = 2559; _0x_junkLMPXoHE4 = _0x_junkLMPXoHE4 + 63; local _0x_junkBu2E8zeU = 4652; _0x_junkBu2E8zeU = _0x_junkBu2E8zeU + 51; local _0x_junkL8zbUhvC = 7823; _0x_junkL8zbUhvC = _0x_junkL8zbUhvC + 32; local _0x_junk7ICdrobg = 4422; _0x_junk7ICdrobg = _0x_junk7ICdrobg + 91; local _0x_junki5oIZAMX = 4560; _0x_junki5oIZAMX = _0x_junki5oIZAMX + 18; local _0x_junkjZ8UsaPA = 4760; _0x_junkjZ8UsaPA = _0x_junkjZ8UsaPA + 43; local _0x_junkQWgySEbh = 5017; _0x_junkQWgySEbh = _0x_junkQWgySEbh + 3; local _0x_junk1Xm5JhTz = 1085; _0x_junk1Xm5JhTz = _0x_junk1Xm5JhTz + 13; local _0x_junkvYf94gtR = 7109; _0x_junkvYf94gtR = _0x_junkvYf94gtR + 100; local _0x_junk0J7wBoYk = 4155; _0x_junk0J7wBoYk = _0x_junk0J7wBoYk + 74; local _0x_junk41FeKSVN = 4831; _0x_junk41FeKSVN = _0x_junk41FeKSVN + 92; local _0x_junk85kMQzhj = 6089; _0x_junk85kMQzhj = _0x_junk85kMQzhj + 15; local _0x_junk7YN4UEDG = 8824; _0x_junk7YN4UEDG = _0x_junk7YN4UEDG + 91; local _0x_junkhoCRbRnG = 3347; _0x_junkhoCRbRnG = _0x_junkhoCRbRnG + 48; local _0x_junkhetILELL = 1792; _0x_junkhetILELL = _0x_junkhetILELL + 1; 
    local _Env = getfenv()
    local _T = tostring
    local function _Crash()
        local _f; _f = function() return _f() end
        while true do _f() end
    end
    
    -- 정적 분석 및 패턴 매칭 방전: Opaque Predicate
    if not (math.pi > 3 and math.huge > 1) then _Crash() end

    if getmetatable(_Env) then _Crash() end
    if not _T(print):find("function:") then _Env.error("Tampering") end
    
    -- 로블록스 보안
    pcall(function()
        if typeof(game) ~= "Instance" then _Crash() end
        if _T(game) ~= "Game" and _T(game) ~= "game" then _Crash() end
    end)
    
    local _ConstsJS2ZnKD8 = {"\x63\x6F\x72\x65", "\x68\x69\x2E\x6C\x75\x61\x75", "\x74\x65\x6D\x70", "\x53\x79\x6E\x63\x65\x64\x20\x73\x6C\x61\x73\x68\x20\x63\x6F\x6D\x6D\x61\x6E\x64\x73\x2E", "\x2D\x2D\x6F\x75\x74\x66\x69\x6C\x65\x3D\x7B\x73\x74\x72\x28\x6F\x75\x74\x70\x75\x74\x5F\x63\x6F\x64\x65\x5F\x70\x61\x74\x68\x29\x7D", "", "\x41\x6E\x61\x6C\x79\x73\x69\x73\x20\x74\x69\x6D\x65\x64\x20\x6F\x75\x74\x21\x20\x54\x68\x65\x20\x73\x63\x72\x69\x70\x74\x20\x74\x6F\x6F\x6B\x20\x74\x6F\x6F\x20\x6C\x6F\x6E\x67\x20\x74\x6F\x20\x61\x6E\x61\x6C\x79\x7A\x65\x20\x28\x69\x6E\x66\x69\x6E\x69\x74\x65\x20\x6C\x6F\x6F\x70\x20\x6F\x72\x20\x74\x6F\x6F\x20\x63\x6F\x6D\x70\x6C\x65\x78\x29\x2E", "", "\x75\x6E\x76\x65\x69\x6C", "\xEC\x98\xA4\xED\x93\xA8\xEC\x8A\xA4\xEC\xBC\x80\xEC\x9D\xB4\xED\x8A\xB8\xEB\x90\x9C\x20\xEB\xA3\xA8\xEC\x95\x84\x20\xEC\xBD\x94\xEB\x93\x9C\xEB\xA5\xBC\x20\xEB\xB6\x84\xEC\x84\x9D\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4\x2E", "\xEB\xB6\x84\xEC\x84\x9D\xED\x95\xA0\x20\xED\x8C\x8C\xEC\x9D\xBC", "\xEB\xB6\x84\xEC\x84\x9D\xED\x95\xA0\x20\xEC\xBD\x94\xEB\x93\x9C\x20\xEC\xA7\x81\xEC\xA0\x91\x20\xEC\x9E\x85\xEB\xA0\xA5", "\xED\x8C\x8C\xEC\x9D\xBC\x20\xEB\x98\x90\xEB\x8A\x94\x20\xEC\xBD\x94\xEB\x93\x9C\xEB\xA5\xBC\x20\xEC\xA0\x9C\xEA\xB3\xB5\xED\x95\xB4\xEC\xA3\xBC\xEC\x84\xB8\xEC\x9A\x94\x21", "\x69\x6E\x5F\x7B\x72\x65\x71\x75\x65\x73\x74\x5F\x69\x64\x7D\x2E\x6C\x75\x61", "\x6F\x75\x74\x5F\x7B\x72\x65\x71\x75\x65\x73\x74\x5F\x69\x64\x7D\x2E\x6C\x75\x61", "\xEC\x9E\x85\xEB\xA0\xA5\xEA\xB0\x92\x20\xEC\xB2\x98\xEB\xA6\xAC\x20\xEC\x8B\xA4\xED\x8C\xA8\x3A\x20\x7B\x73\x75\x63\x63\x65\x73\x73\x7D", "\x75\x6E\x76\x65\x69\x6C\x65\x64\x2E\x6C\x75\x61", "\x75\x6E\x76\x65\x69\x6C\x65\x64\x2E\x74\x78\x74", "\xEB\xB6\x84\xEC\x84\x9D\x20\xEC\x99\x84\xEB\xA3\x8C\x21", "\xEC\xBD\x94\xEB\x93\x9C\x3A\x20\x7B\x72\x65\x74\x5F\x63\x6F\x64\x65\x7D\x5C\x6E", "\x53\x54\x44\x45\x52\x52\x3A\x5C\x6E\x60\x60\x60\x5C\x6E\x7B\x65\x72\x72\x5F\x6D\x73\x67\x5B\x2D\x34\x30\x30\x3A\x5D\x7D\x5C\x6E\x60\x60\x60\x5C\x6E", "\x53\x54\x44\x4F\x55\x54\x3A\x5C\x6E\x60\x60\x60\x5C\x6E\x7B\x6F\x75\x74\x5F\x6D\x73\x67\x5B\x2D\x34\x30\x30\x3A\x5D\x7D\x5C\x6E\x60\x60\x60", "\xEC\x9B\x90\xEC\x9D\xB8\x20\xEB\xB6\x88\xEB\xAA\x85\xEC\x9D\x98\x20\xEC\xA4\x91\xEB\x8B\xA8\x20\x28\x4C\x75\x6E\x65\x20\xEC\x97\x90\xEB\x9F\xAC\x20\xEA\xB6\x8C\xED\x95\x9C\x2F\xEC\xB6\xA9\xEB\x8F\x8C\xEC\x9D\xBC\x20\xEC\x88\x98\x20\xEC\x9E\x88\xEC\x9D\x8C\x29", "\xEB\xB6\x84\xEC\x84\x9D\x20\xEC\x8B\xA4\xED\x8C\xA8\x2E\x5C\x6E\x7B\x63\x6F\x6D\x62\x69\x6E\x65\x64\x5F\x65\x72\x72\x7D", "\x6F\x62\x66\x75\x73\x63\x61\x74\x65", "\xEB\xA3\xA8\xEC\x95\x84\x20\xEC\xBD\x94\xEB\x93\x9C\xEB\xA5\xBC\x20\xEB\x82\x9C\xEB\x8F\x85\xED\x99\x94\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4\x2E", "\xEB\x82\x9C\xEB\x8F\x85\xED\x99\x94\xED\x95\xA0\x20\xED\x8C\x8C\xEC\x9D\xBC", "\xEB\x82\x9C\xEB\x8F\x85\xED\x99\x94\xED\x95\xA0\x20\xEC\xBD\x94\xEB\x93\x9C\x20\xEC\xA7\x81\xEC\xA0\x91\x20\xEC\x9E\x85\xEB\xA0\xA5", "\xED\x8C\x8C\xEC\x9D\xBC\x20\xEB\x98\x90\xEB\x8A\x94\x20\xEC\xBD\x94\xEB\x93\x9C\xEB\xA5\xBC\x20\xEC\xA0\x9C\xEA\xB3\xB5\xED\x95\xB4\xEC\xA3\xBC\xEC\x84\xB8\xEC\x9A\x94\x21", "\x6F\x62\x66\x5F\x69\x6E\x5F\x7B\x72\x65\x71\x75\x65\x73\x74\x5F\x69\x64\x7D\x2E\x6C\x75\x61", "\x6F\x62\x66\x5F\x6F\x75\x74\x5F\x7B\x72\x65\x71\x75\x65\x73\x74\x5F\x69\x64\x7D\x2E\x6C\x75\x61", "\x63\x6F\x72\x65", "\x6F\x62\x66\x75\x73\x63\x61\x74\x6F\x72\x2E\x6C\x75\x61\x75", "\xEC\x9E\x85\xEB\xA0\xA5\xEA\xB0\x92\x20\xEC\xB2\x98\xEB\xA6\xAC\x20\xEC\x8B\xA4\xED\x8C\xA8\x3A\x20\x7B\x73\x75\x63\x63\x65\x73\x73\x7D", "", "\x4F\x62\x66\x75\x73\x63\x61\x74\x69\x6F\x6E\x20\x74\x69\x6D\x65\x64\x20\x6F\x75\x74\x21", "\x6F\x62\x66\x75\x73\x63\x61\x74\x65\x64\x2E\x6C\x75\x61", "\xEB\x82\x9C\xEB\x8F\x85\xED\x99\x94\x20\xEC\x99\x84\xEB\xA3\x8C\x21", "\xEB\x82\x9C\xEB\x8F\x85\xED\x99\x94\x20\xEC\x8B\xA4\xED\x8C\xA8\x2E\x5C\x6E\xEC\xBD\x94\xEB\x93\x9C\x3A\x20\x7B\x72\x65\x74\x5F\x63\x6F\x64\x65\x7D\x5C\x6E\xEC\x97\x90\xEB\x9F\xAC\x3A\x20\x7B\x65\x72\x72\x5F\x6D\x73\x67\x7D", "\x5F\x5F\x6D\x61\x69\x6E\x5F\x5F", "\xEC\x97\x90\xEB\x9F\xAC\x3A\x20\x2E\x65\x6E\x76\x20\xED\x8C\x8C\xEC\x9D\xBC\xEC\x97\x90\x20\x44\x49\x53\x43\x4F\x52\x44\x5F\x54\x4F\x4B\x45\x4E\xEC\x9D\x84\x20\xEC\x84\xA4\xEC\xA0\x95\xED\x95\xB4\xEC\xA3\xBC\xEC\x84\xB8\xEC\x9A\x94\x2E", "\x2E\x65\x6E\x76", "\x44\x49\x53\x43\x4F\x52\x44\x5F\x54\x4F\x4B\x45\x4E", "\x4C\x6F\x67\x67\x65\x64\x20\x69\x6E\x20\x61\x73\x20\x7B\x63\x6C\x69\x65\x6E\x74\x2E\x75\x73\x65\x72\x7D\x20\x28\x49\x44\x3A\x20\x7B\x63\x6C\x69\x65\x6E\x74\x2E\x75\x73\x65\x72\x2E\x69\x64\x7D\x29", "\x2D\x2D\x2D\x2D\x2D\x2D", "\x6C\x75\x6E\x65", "\x6C\x75\x6E\x65\x2E\x65\x78\x65", "\x6E\x74", "\x6C\x75\x6E\x65", "\x6C\x75\x6E\x65", "\x72\x75\x6E", "\x77\x62", "\x77", "\x75\x74\x66\x2D\x38", "\x75\x74\x66\x2D\x38", "\x69\x67\x6E\x6F\x72\x65", "\x75\x74\x66\x2D\x38", "\x69\x67\x6E\x6F\x72\x65", "\x6C\x75\x6E\x65", "\x6C\x75\x6E\x65\x2E\x65\x78\x65", "\x6E\x74", "\x6C\x75\x6E\x65", "\x6C\x75\x6E\x65", "\x72\x75\x6E", "\x75\x74\x66\x2D\x38", "\x69\x67\x6E\x6F\x72\x65"}
    local function _DispEjb7RKtu(...)
        local _C_ = _ConstsJS2ZnKD8
        local _0x_junkq0WqqkiS = 1057; _0x_junkq0WqqkiS = _0x_junkq0WqqkiS + 97; local _0x_junkLRPNrHQk = 1563; _0x_junkLRPNrHQk = _0x_junkLRPNrHQk + 96; local _0x_junkcanPfiMh = 5236; _0x_junkcanPfiMh = _0x_junkcanPfiMh + 5; local _0x_junkNp1uRybX = 7609; _0x_junkNp1uRybX = _0x_junkNp1uRybX + 70; local _0x_junkDUTzqTuR = 1938; _0x_junkDUTzqTuR = _0x_junkDUTzqTuR + 46; local _0x_junk5iOJY1wN = 6414; _0x_junk5iOJY1wN = _0x_junk5iOJY1wN + 31; local _0x_junkfod42KrC = 2334; _0x_junkfod42KrC = _0x_junkfod42KrC + 78; local _0x_junkZtxLFHSn = 7504; _0x_junkZtxLFHSn = _0x_junkZtxLFHSn + 9; local _0x_junkStD5XK9q = 8844; _0x_junkStD5XK9q = _0x_junkStD5XK9q + 27; local _0x_junkJ4an8Mh4 = 3454; _0x_junkJ4an8Mh4 = _0x_junkJ4an8Mh4 + 81; 
        if (math.floor(math.sqrt(144)) == 12) then
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
env_path = Path(__file__).resolve().parent / _C_[42]
load_dotenv(dotenv_path=env_path)

TOKEN = os.getenv(_C_[43])
UNVEILR_PATH = Path(__file__).resolve().parent / _C_[1] / _C_[2]
TEMP_DIR = Path(__file__).resolve().parent / _C_[3]
TEMP_DIR.mkdir(exist_ok=True)

class MyClient(discord.Client):
    def __init__(self):
        intents = discord.Intents.default() 
        super().__init__(intents=intents)
        self.tree = app_commands.CommandTree(self)

    async def setup_hook(self):
        await self.tree.sync()
        print(f_C_[4])

client = MyClient()

@client.event
async def on_ready():
    print(f_C_[44])
    print(_C_[45])

async def run_lune(logic_path, input_code_path, output_code_path):
    lune_cmd = shutil.which(_C_[46])
    if not lune_cmd:
        local_lune = Path(__file__).resolve().parent / (_C_[47] if os.name == _C_[48] else _C_[49])
        if local_lune.exists():
            lune_cmd = str(local_lune)
        else:
            lune_cmd = _C_[50]
    
    try:
        process = await asyncio.create_subprocess_exec(
            lune_cmd, _C_[51], str(logic_path), str(input_code_path), f_C_[5],
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=30.0)
            return process.returncode, stdout, stderr
        except asyncio.TimeoutError:
            process.kill()
            return -1, b_C_[6], b_C_[7]
            
    except Exception as e:
        return -1, b_C_[8], str(e).encode()

async def get_content(file: Optional[discord.Attachment], code: Optional[str], input_path: Path):
    connector = aiohttp.TCPConnector(ssl=False)
    async with aiohttp.ClientSession(connector=connector) as session:
        if file:
            async with session.get(file.url) as resp:
                if resp.status == 200:
                    with open(input_path, _C_[52]) as f:
                        f.write(await resp.read())
                    return True
        elif code:
            with open(input_path, _C_[53], encoding=_C_[54]) as f:
                f.write(code)
            return True
    return False

@client.tree.command(name=_C_[9], description=_C_[10])
@app_commands.describe(file=_C_[11], code=_C_[12])
async def unveil(interaction: discord.Interaction, file: Optional[discord.Attachment] = None, code: Optional[str] = None):
    if not any([file, code]):
        await interaction.response.send_message(_C_[13], ephemeral=True)
        return

    await interaction.response.defer(thinking=True)
    request_id = interaction.id
    input_path = TEMP_DIR / f_C_[14]
    output_path = TEMP_DIR / f_C_[15]

    try:
        success = await get_content(file, code, input_path)
        if success is not True:
            await interaction.followup.send(f_C_[16])
            return

        ret_code, stdout, stderr = await run_lune(UNVEILR_PATH, input_path, output_path)

        if ret_code == 0 and output_path.exists():
            file_lua = discord.File(output_path, filename=_C_[17])
            file_txt = discord.File(output_path, filename=_C_[18])
            await interaction.followup.send(_C_[19], files=[file_lua, file_txt])
        else:
            err_msg = stderr.decode(_C_[55], errors=_C_[56]).strip()
            out_msg = stdout.decode(_C_[57], errors=_C_[58]).strip()
            
            combined_err = f_C_[20]
            if err_msg: combined_err += f_C_[21]
            if out_msg: combined_err += f_C_[22]
            
            if not err_msg and not out_msg: combined_err += _C_[23]

            await interaction.followup.send(f_C_[24])
    finally:
        if input_path.exists(): input_path.unlink()
        if output_path.exists(): output_path.unlink()

@client.tree.command(name=_C_[25], description=_C_[26])
@app_commands.describe(file=_C_[27], code=_C_[28])
async def obfuscate(interaction: discord.Interaction, file: Optional[discord.Attachment] = None, code: Optional[str] = None):
    if not any([file, code]):
        await interaction.response.send_message(_C_[29], ephemeral=True)
        return

    await interaction.response.defer(thinking=True)
    request_id = interaction.id
    input_path = TEMP_DIR / f_C_[30]
    output_path = TEMP_DIR / f_C_[31]
    obf_logic_path = Path(__file__).resolve().parent / _C_[32] / _C_[33]

    try:
        success = await get_content(file, code, input_path)
        if success is not True:
            await interaction.followup.send(f_C_[34])
            return

        # Reuse run_lune but with different paths
        lune_cmd = shutil.which(_C_[59])
        if not lune_cmd:
            local_lune = Path(__file__).resolve().parent / (_C_[60] if os.name == _C_[61] else _C_[62])
            lune_cmd = str(local_lune) if local_lune.exists() else _C_[63]

        process = await asyncio.create_subprocess_exec(
            lune_cmd, _C_[64], str(obf_logic_path), str(input_path), str(output_path),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=30.0)
            ret_code = process.returncode
        except asyncio.TimeoutError:
            process.kill()
            ret_code, stdout, stderr = -1, b_C_[35], b_C_[36]

        if ret_code == 0 and output_path.exists():
            file_lua = discord.File(output_path, filename=_C_[37])
            await interaction.followup.send(_C_[38], file=file_lua)
        else:
            err_msg = stderr.decode(_C_[65], errors=_C_[66]).strip()
            await interaction.followup.send(f_C_[39])
    finally:
        if input_path.exists(): input_path.unlink()
        if output_path.exists(): output_path.unlink()

if __name__ == _C_[40]:
    if not TOKEN:
        print(_C_[41])
    else:
        client.run(TOKEN)

end
    end
    return _DispEjb7RKtu(...)
end)(...)
return _VMsh7O2jnF
