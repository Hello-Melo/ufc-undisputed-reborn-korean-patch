# UFC Undisputed Reborn 한국어 패치

**Undisputed Reborn 1.1 / Xbox 360 / Xenia**용 비공식 한국어 패치입니다.

## 다운로드

**[v1.01 릴리스 안내](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/tag/v1.01) · [한국어 패치 ZIP 다운로드](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/download/v1.01/UFC-Undisputed-Reborn-Korean-Melo-v1.01.zip)**

**2026-11-11 수정본**입니다. 버전은 v1.01로 유지합니다. 이전 v1.01 사용자도 새 ZIP의 설치.cmd로 업데이트할 수 있습니다.

게임과 **Undisputed Reborn 1.1 모드는 별도로 준비**해야 합니다. 게임·모드 본체와 Xenia 실행 파일은 제공하지 않습니다.
이 저장소는 Reborn 전용이며 PS3·RPCS3용 Forever 패치와 호환되지 않습니다. GitHub의 Source code 압축 파일은 설치용 패치 ZIP이 아닙니다.

## 작업 내용

- 공통 UI·경기·연습·튜토리얼·기록·커리어 문구 한글화
- 확인된 선수·심판 이름, 커리어 이름 후보 및 오프라인 문구 한글화
- 자음·모음 조합 한글 입력과 저장·재로드 지원
- 커리어 모드 한글 깨짐 수정 및 뉴스 번역 보완
- 커리어 선수 이미지 생성·저장 문제 수정
- 경기 프레임 저하 수정
- 이름·글꼴·화면 배치와 로딩 안내 표시 개선
- 자동 설치·판본 검사·백업·업데이트·복원

[작업 내용](docs/WORK.md) · [변경 기록](docs/CHANGELOG.md) · [검증 범위](docs/VALIDATION.md)

## 설치 방법

1. Reborn 1.1과 Xenia를 별도로 준비합니다.
2. [한국어 패치 ZIP](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/download/v1.01/UFC-Undisputed-Reborn-Korean-Melo-v1.01.zip)을 모두 압축 해제합니다.
3. Xenia를 완전히 종료한 뒤 설치.cmd를 실행합니다.
4. Reborn 게임과 Xenia 폴더를 선택하고 설치 후 기존 방법으로 실행합니다.

기존 v1.0 beta·v1.01도 같은 방법으로 업데이트합니다. 검사.cmd는 상태만 확인하며, 복원.cmd는 가장 최근 설치 전 상태로 되돌립니다. 백업 폴더는 유지하세요.

이미지 저장에 필요한 Reborn 게임별 옵션만 자동으로 설정하며, 전역 그래픽 옵션·해상도·키 설정·저장 데이터는 유지합니다.
기존에 이미지가 깨졌다면 **커리어 → 내 선수 → 외모 편집 → 저장 후 계속하기**로 다시 생성하세요.

[설치·백업·복원 안내](docs/INSTALL.md)

## 이용 조건

번역·패치·설치 도구의 **상업적 이용·판매·유료 배포를 금지**합니다. 제3자 구성요소에는 각각의 원래 라이선스가 적용됩니다.
게임·Reborn 본체·Xenia·개인 설정·저장·진단본·배경 미리보기는 배포하지 않습니다. 비공식 패치이며 권리자의 요청이나 문제가 확인되면 배포 중단·삭제·수정을 진행할 수 있습니다.

[이용 조건 전문](docs/TERMS.md) · [Pretendard 라이선스](licenses/Pretendard/OFL.txt)

## 확인 범위

사용자가 부팅·메뉴·경기·커리어 초반과 이번 수정 사항을 확인했으며 설치 도구는 64개 검사를 통과했습니다. 커리어 전체 진행과 모든 모드·장면을 전수 플레이한 것은 아닙니다.
온라인 번역과 보류한 선수·관계자 슬롯은 제외합니다. 영어 음성·해설·영상 음성을 유지합니다. 입장 장면의 일부 어깨·팔 이음새는 패치 전에도 확인된 현상입니다.

## 무결성 확인

- 파일: UFC-Undisputed-Reborn-Korean-Melo-v1.01.zip
- SHA-256: `ec71998c576f8d5fad83192656f59d01a0842567b9e2f7c1f37c8d47ecb96b38`
- [체크섬 파일](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/download/v1.01/UFC-Undisputed-Reborn-Korean-Melo-v1.01.sha256)

설치 도구 소스는 installer/, 적용 판본과 파일 해시는 release-manifest.json에서 확인할 수 있습니다.
