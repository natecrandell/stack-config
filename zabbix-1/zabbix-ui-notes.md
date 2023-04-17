# Zabbix UI Notes

Checks

I've had a rough time overall finding a Zabbix check to ensure a particular service is running. I've simply settled on manually creating a check for port listening instead.

- service.info - This check won't work for me. It's apparently exclusively for Windows hosts.
- port listening
  - ITEM - Type: Simplecheck, Key: net.tcp.service[(service),,(port#)] (see [docs](https://www.zabbix.com/documentation/current/en/manual/appendix/items/service_check_details) for acceptable service values)
  - TRIGGER - Expression: max(/[host]/net.tcp.service[,,51413],#3)=0
