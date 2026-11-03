/// 내 메시지 전송 상태: 전송 완료(서버 확인), 전송 중(서버 응답 대기), 실패(연결 끊김·응답 시간 초과)
enum ChatMessageSendStatus { sent, sending, failed }
