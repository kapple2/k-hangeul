# 변경 기록 (Changelog)

> English version: [CHANGELOG_en.md](CHANGELOG_en.md)

버전 번호는 저장소 맨 위의 `VERSION` 파일 한 곳에만 적습니다. 빌드가 시작 화면의 `v1.1b` 글자를 이 파일에서 가져옵니다.
버전을 올릴 때는 이 파일 맨 위에 새 항목을 쓰고, 사용 설명서(`docs/MANUAL.md`, `docs/MANUAL_en.md`)의 버전 글자도 바꿉니다.

## 1.1b

- Saturn 128K 카드 지원. `K-HANGEUL.bin` 하나가 일반 16KB 랭귀지 카드와 Saturn 카드에서 모두 동작합니다.
  Saturn 카드에서는 드라이버·글꼴·자료가 맨 위 뱅크에 들어가서 `$0800-$1FFF`가 비고, BASIC `HIMEM`은 `$9400` 그대로입니다.
  일반 카드에서는 동작과 메모리 배치가 1.0b와 같습니다.
- 시작 화면에 Saturn 카드 줄이 나옵니다 (`$D000 새턴 카드 뱅크N에 로드됨`).
- 프로그램을 불러온 뒤 `$9400-$95FF`가 지워졌을 때 다시 세우는 고정 진입점 `$D3FA` (`jmp STATEINIT`), 버전 바이트 `$D3FD=$01`, 확인 바이트 `$D3FE=$5A`. 자세한 내용은 `docs/MEMORY_LAYOUT.md`.

## 1.0b

- 한글2를 고친 첫 배포판. 16KB 랭귀지 카드, DOS 3.3.
