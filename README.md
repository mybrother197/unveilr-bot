# Unveilr Discord Bot (Python Version)

이 로봇은 `The Big Unveilr`를 사용하여 오퓨스케이트된 Roblox 스크립트를 디스코드 슬래시 명령어로 분석합니다.
**Message Content Intent 권한이 필요하지 않습니다.**

## 설정 방법

1.  **필수 요소 설치:**
    *   [Python 3.8+](https://www.python.org/)
    *   [Lune](https://github.com/lune-org/lune) (시스템 PATH에 등록되어 있어야 합니다)

2.  **의존성 설치:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **토큰 설정:**
    *   `.env.example` 파일을 `.env`로 이름을 바꿉니다.
    *   [Discord Developer Portal](https://discord.com/developers/applications)에서 봇의 **TOKEN**을 복사하여 넣습니다.
    *   OAuth2 URL Generator에서 `applications.commands` 권한을 체크하여 봇을 서버에 초대하세요.

4.  **봇 실행:**
    ```bash
    python bot.py
    ```

## 사용법

*   디스코드에서 `/unveil` 명령어를 입력하고 분석할 `.lua` 파일을 첨부하세요.
*   분석이 완료되면 봇이 결과 파일(`unveiled.lua`)을 답변으로 보내줍니다.

## 주의사항
*   `lune` 명령어가 터미널에서 정상적으로 실행되는지 먼저 확인하세요.
    ```bash
    lune --version
    ```
