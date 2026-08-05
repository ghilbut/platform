# Chrome

[Argo CD](https://argo.ghilbut.com/cd) 같은 내부 시스템은 LAN CoreDNS를 사용한다.

## 내부 시스템 접속

1. [Security settings](chrome://settings/security)에서 `Use secure DNS`를 끈다.
2. [DNS cache](chrome://net-internals/#dns)에서 `Clear host cache`를 선택한다.
3. [Socket pools](chrome://net-internals/#sockets)에서 `Flush socket pools`를 선택한다.
4. Chrome을 완전히 종료한 뒤 다시 시작한다.
