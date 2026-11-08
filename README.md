# UFC Undisputed Reborn 한국어 패치

**Undisputed Reborn 1.1 / Xbox 360 / Xenia** 구성을 위한 Melo의 비공식 한국어 패치입니다.

## 다운로드

**[v1.0 beta 릴리스 안내](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/tag/v1.0-beta) · [한국어 패치 ZIP 다운로드](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/download/v1.0-beta/UFC-Undisputed-Reborn-Korean-Melo-v1.0-beta.zip)**

게임과 **Undisputed Reborn 1.1 모드는 별도로 준비**해야 합니다. 게임·모드 본체와 Xenia 실행 파일은 제공하지 않습니다.

이 저장소는 Reborn 전용입니다. **PS3·RPCS3용 Forever 한글패치와 호환되지 않습니다.** GitHub의 Source code 압축 파일은 설치용 패치 ZIP이 아닙니다.

## 작업 내용

| 구분 | 내용 |
| --- | --- |
| UI·경기 | 메뉴·설정·가이드·경기·연습·튜토리얼·기록 문구 한글화 |
| 커리어·오프라인 | 커리어 진행, 상점·대진·해금 조건·경기장·체육관·인물 문구 정리 |
| 이름 | 확인된 실제 선수와 심판 표기, 커리어 이름·성·별명 후보 440개 한글화 |
| 한글 입력·글꼴 | 자음·모음 조합 입력, 저장·재로드, Pretendard Bold 기반 표시 보완 |
| 표시 보완 | 선수 선택·입장·경기·결과 이름 표시와 로딩 문구 간격 갱신 |
| 설치 도구 | 판본 검사, 자동 백업·설치·복원, 중복 적용 방지 |

[자세한 작업 내용](docs/WORK.md) · [검증 범위](docs/VALIDATION.md)

## 설치 방법

1. Reborn 1.1과 Xenia를 별도로 준비하고 정상 실행을 확인합니다.
2. [한국어 패치 ZIP](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/download/v1.0-beta/UFC-Undisputed-Reborn-Korean-Melo-v1.0-beta.zip)을 모두 압축 해제합니다.
3. Xenia를 완전히 종료하고 `설치.cmd`를 실행합니다.
4. Reborn 게임과 Xenia가 들어 있는 폴더를 선택하고, 설치 완료 후 기존 방법으로 실행합니다.

`검사.cmd`는 설치 상태만 확인하고, `복원.cmd`는 설치 때 만든 백업으로 되돌립니다. 설정·저장 데이터와 기존 Reborn 패치는 변경하지 않습니다.

[설치·백업·복원 안내](docs/INSTALL.md)

## 확인 범위와 제외 항목

- 사용자 확인: 부팅·메뉴·경기·커리어 초반, 이름·심판·오프라인 문구, 한글 입력·저장·재로드, 경기 진입·PRIDE 로딩
- 설치 도구: Windows PowerShell 5.1에서 설치·중복 설치·복원·오류 거부·실패 복구 등 18개 검사
- 커리어 전체 진행과 모든 선수·장면을 전수 플레이한 것은 아닙니다.
- 온라인 번역과 미확정 선수·관계자 슬롯 53개는 제외합니다.
- 영어 음성·해설·영상 음성과 실제 사용이 확인되지 않은 DLC 원문은 유지합니다.
- 입장 장면의 일부 어깨·팔 이음새는 패치 전에도 확인된 현상이며 이 패치의 수정 범위가 아닙니다.

## 이용 조건

**Melo가 제작한 번역·패치·설치 도구의 상업적 이용·판매·유료 배포를 금지합니다.** 제3자 구성요소에는 각각의 원래 라이선스가 적용됩니다.

게임·Reborn 모드 본체·Xenia·개인 설정·저장·진단본·배경 미리보기는 배포하지 않습니다. 비공식 패치이며, 권리자의 요청이나 문제가 확인되면 배포 중단·삭제·수정 조치를 진행할 수 있습니다.

[이용 조건 전문](docs/TERMS.md) · [Pretendard 라이선스](licenses/Pretendard/OFL.txt)

## 무결성 확인

- 파일: `UFC-Undisputed-Reborn-Korean-Melo-v1.0-beta.zip`
- SHA-256: `e5ead07caabb350e76044cd2121603ea51f95721940623549b7be84162915bad`
- [체크섬 파일](https://github.com/Hello-Melo/ufc-undisputed-reborn-korean-patch/releases/download/v1.0-beta/UFC-Undisputed-Reborn-Korean-Melo-v1.0-beta.sha256)

설치 도구 소스는 `installer/`, 대상 판본과 변경 파일 해시는 `release-manifest.json`에서 확인할 수 있습니다. 설치에는 릴리스의 완성된 ZIP을 사용하세요.
