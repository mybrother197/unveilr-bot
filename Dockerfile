# 1. 파이썬 환경 설정
FROM python:3.12-slim

# 2. 필수 패키지 설치 (lune 실행 및 git 클론용)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# 3. Lune 설치 (Linux x86_64 버전)
RUN wget https://github.com/lune-org/lune/releases/download/v0.10.4/lune-0.10.4-linux-x86_64.zip \
    && unzip lune-0.10.4-linux-x86_64.zip \
    && mv lune /usr/local/bin/ \
    && rm lune-0.10.4-linux-x86_64.zip

# 4. 작업 디렉토리 설정
WORKDIR /app

# 5. 요구 사항 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. 소스 코드 복사
COPY . .

# 7. 실행 권한 부여
RUN chmod +x /usr/local/bin/lune

# 8. 봇 실행
CMD ["python", "bot.py"]
