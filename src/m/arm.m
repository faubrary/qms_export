 ; Программа обработки протокола arm - обмена данными между сервером qMS и клиентом qWARM / qARM(depricated)
 ; 
 ; edit rules: сокращённый синтаксис команд; команды и функции в нижнем регистре; после точки блока пробел перед первой командой
 ; ответственный Roman Alekseev (roman.alekseev@sparm.com)
 ; 
 ; 
 ; Глобальные переменные:
 ; * %gSET - список допустимых команд в формате "команда1,синонимКоманды1:команда2,синонимКоманды2"
 ; * %gZU - флаг включения преобразование входящих/исходящих строк для команд zg/zs/zk/zx/zzs из/в UTF-16; по умолчанию 0
 ; * %protIndex - глобальная переменная для индекса для передачи протокола; Используется в метке wrgl
 ; * %noRtDecode - без преобразования ответа от клиента в Event(), определяется в checkVer()
 ; * %crossClt - флаг кроссплатформанного клиента (?) (формируется в checkVer) 
 ; * %cont - добаление заголовка пакета для первой порции данных для wrgl()
 ; * %curJob - номер текущего процесса (формируется в begin)
 ; * %srvident - номер серверного пакета
 ; 
 ; #Changelog:
 ; 20190204 - Event: q $$ZZCVTiul(b) : encode runTime result to $zchset
 ; 20200227 random #75985 - Added "gu" command. + %gZU / %gZUU
 ; 20210315 @AKU Добавлены большие блоки, исправлено формирование идентификатора пакета. !NB! требует qmumps версии 1.08 и выше
 ; 20240802 ralekseev (#326293) ver 2.8 переработка чтения протокола; конвертации из/в UTF-16
 ;                      Используется только протокол из глобала ^mtempqprot
 ; 20241023 ralekseev (#336838) для версии GT.M V7.0 исправлена работа $zcvt() (порядок операторов, отсутствие BOM, обработка $c(152))

Ver() ;Версия программы. Вызывается из qmumps для запроса номера версии arm.m
 q "2.8"
main(%gTYP,%gZDx) ; Подпрограмма вызывается из qmumps в основном цикле обработки запроса от клиента
 s %gLEN=$zl(%gZDx) ; длина входящей строки в байтах
 s %gUTIME=0
 s %gDev=$P
 i '$d(%ydbVer7) s %ydbVer7=$s($text(comparePlatformVersion^updateCommon)="":0,$$comparePlatformVersion^updateCommon("7.0")<0:0,1:1) ;флаг GT.M V7.0 (исправлено $zcvt())
 s %gSET="g,get,zg,gu:s,set:k,kill:x,o:zs:zcmd1:zcmd11:zcmd2:zcmdbytes:zauth:zprot:zcmd12"
 ;i $i(%ARMLog) s ^mtempARMLog($j,%ARMLog,"1Start")=$$gettime()
 s %gZU=0,%gZUU=0
 ;i %gTYP=4 q $$ZZCVTiul(%gZDx) ; Return answer of event handler
 s %gZC=$zpi(%gZDx," ") ; команда протокола
 i %gZC="" d addlog("Empty command") q
 s %gZD=$ze(%gZDx,$zl(%gZC)+2,%gLEN)
 s:%gZC="=" %gZC="zg"
 ;i $d(%ARMLog) s ^mtempARMLog($j,%ARMLog,"2Start")=$$gettime()_"<-->"_%gZC_"-->"_%gZDx
 f i=1:1 s %gTYP=$zpi(%gSET,":",i) q:%gTYP=""  d  q:%gTYP=""
 . f j=1:1 q:$zpi(%gTYP,",",j)=""  i $zpi(%gTYP,",",j)=%gZC s %gTYP=""
 k %protIndex ; глобальная переменная для индекса передачи протокола; Используется в метке wrgl
 x "d "_$s(i=1:"zzg",i=2:"zzs",i=3:"zzk",i=4:"zzx",i=5:"zzzs",i=6:"zzzcmd1",i=7:"zzzcmd11",i=8:"zzzcmd2",i=9:"zzzcmdbytes",i=10:"zauth",i=11:"zprot",i=12:"zzzcmd12",1:"zzerr")
 q %gD
Event() ; посыл сигнала клиенту через qmumps в процессе обработки сообщения от клиента (используется в RunTimeAction)
 s bf=""
 ; сборка накопленного протокола; выход из цикла через контроль изменения длины bf (чтобы не использовать лишние строки)
 n %gres k %protIndex f  s bf=bf_$g(^mtempqprot("P",$j,"M",$i(%protIndex))) q:'$d(^mtempqprot("P",$j,"M",%protIndex))
 i $g(qruntimeprot)>0 f i=1:1:qruntimeprot s bf=bf_$g(qruntimeprot(i)) ; используется в дельфиском клиенте
 i $d(%ARMLog) s ^mtempARMLog($j,$i(%ARMLog),"Event-arm")=bf
 i $d(^mtempqprot("P",$j,"N")) s bf=$$ZZCVToul($$addIdent(""))_bf
 e  s bf=$$ZZCVToul($$addIdent(bf))
 k ^mtempqprot("P",$j,"M"),^mtempqprot("P",$j,"N"),%protIndex
 s %gres="" d &mevent.sendevent(bf,.%gres)
 i $d(%ARMLog) s ^mtempARMLog($j,$i(%ARMLog),"Event-arm")="res="_%gres
 q:noRtDecode %gres q $$ZZCVTiul(%gres)
wrgl() ; Вызывается из qmumps для чтения следующего сообщения из протокола
 ; глобальная переменная %cont - добаление заголовка пакета для первой порции данных
 n bf s bf=$g(^mtempqprot("P",$j,"M",$i(%protIndex)))
 i bf="" k %cont,%protIndex,^mtempqprot("P",$j,"M"),^mtempqprot("P",$j,"N") q "" ; окончание обработки протокола (больше нет данных) - очистка служебных переменных
 if $data(^mtempqprot("P",$j,"N")) s:'$d(%cont) bf=$$ZZCVToul($$addIdent(""))_bf,%cont=""
 e  s bf=$$ZZCVToul(bf)
 ;i $d(%ARMLog) s ^mtempARMLog($j,$i(%ARMLog),"wrgl")=bf

 q bf
addIdent(str) ; добавление заголовка посылки к строке
 if %crossClt,$i(%srvident) s str="I"_%ident_$tr($j(%srvident#10000,4)," ",0)_" "_str
 q str
begin() ; обработчик события begin - старт процесса, вызывается из qmumps
 s %srvident=0,%crossClt=0,%curJob=$job
 d BaseCleGT^VObj
 q
mainC
 q
callOnServerIdle(sec) ; обработчик события SeverIdle - сервер в состоянии ожидания запроса от клиента (#204276)
 ; Вызывается из qmumps раз в секунду
 q:$g(%gTimeOnServerIdle)=-1
 n $et s $et="d errcallOnServerIdle^"_$p($st($st,"PLACE"),"^",2)_" q  "
 i ($zut-$g(%gTimeOnServerIdle))'<$g(sec,1000000) s %gTimeOnServerIdle=$zut d:$text(onServerIdle^ClientApi)'="" onServerIdle^ClientApi()
 q
errcallOnServerIdle
 s %gTimeOnServerIdle=-1 q

 ; Обработка команд протокола arm
zzerr  ; ошибочная команда / неподдерживаемая команда
 d addlog("Bad command zzerr "_%gZC_"   "_%gLEN)
 s %gD=""
 q
zzget ; get - взятие значения переменной/узла глобала
zzg
zzzg
 i %gZU s %gZD=$$ZZCVTiul(%gZD)
 s:($g(%gZC)="gu")&($zchset="M") %gZUU=1 ; 20200227 random #75985
 i $g(%gZUU) s %gZD=$$ZCVT^VObj(%gZD,"I","UTF8") ; 20200227 random #75985
 d addlog("zzzg "_%gZD)
 s @("%gD="_%gZD)
 i $g(%gZUU) s %gD=$$ZCVT^VObj(%gD,"O","UTF8") ; 20200227 random #75985
 i %gZU s %gD=$$ZZCVToul(%gD)
 q
zzset ; set - установка значения переменной/узла глобала
zzs
 i %gZU s %gZD=$$ZZCVTiul(%gZD)
 d addlog("zzs "_%gZD)
 s @%gZD
 s %gD="ok"
 i %gZU s %gD=$$ZZCVToul(%gD)
 q
zzkill ; kill - удаление переменной/глобала
zzk
 i %gZU s %gZD=$$ZZCVTiul(%gZD)
 d addlog("zzk "_%gZD)
 k @%gZD
 s %gD="ok"
 i %gZU s %gD=$$ZZCVToul(%gD)
 q
zzx ; xecute - исполнение кода с преобразованием через $$Action^Lib
zzo
 i %gZU s %gZD=$$ZZCVTiul(%gZD)
 d addlog("zzo "_%gZD)
 d
 . x $$Action^Lib(%gZD)
 s %gD="ok"
 i %gZU s %gD=$$ZZCVToul(%gD)
 q
zzzs
 i %gZU s %gZD=$$ZZCVTiul(%gZD)
 d addlog("zzs "_%gZD)
 s @$P(%gZD,"=")=$E(%gZD,$L($P(%gZD,"="))+2,$L(%gZD))
 s %gD="ok"
 i %gZU s %gD=$$ZZCVToul(%gD)
 q
zzzcmd1
 d addlog("zzzcmd1 "_%gZD)
 s %gD=$$zcmd1(%gZD)
 q
zzzcmd11
 n %gzl,%gzbfu
 s %gzl=$p(%gZD," "),%gZD=$ze(%gZD,$zl(%gzl)+2,$zl(%gZD))
 d addlog(%gzl_"-->")
 ;i $d(%ARMLog) s ^mtempARMLog($j,%ARMLog,"5PACK1")=%gZD
 s %gZD=$$ZZCVTiul(%gZD)
 d addlog("zzzcmd11 "_%gZD)
 i $d(%ARMLog) s ^mtempARMLog($j,%ARMLog,"5PACK2")=%gZD
 s %gD=$$zcmd1(%gZD)
 q
zzzcmd12
 n %gzl,%gzbfu
 s %ident=$ze(%gZD,1,4)
 s %gZD=$ze(%gZD,10,$l(%gZD))
 s %gzl=$p(%gZD," "),%gZD=$ze(%gZD,$l(%gzl)+2,$l(%gZD))
 d addlog(%gzl_"-->")
 s %gZD=$$ZZCVTiul(%gZD)
 d addlog("zzzcmd12 "_%gZD)
 s %gD=$$ZZCVToul("I"_%ident_$tr($j($g(%srvident)#10000,4)," ",0)_" ")_$$zcmd1(%gZD)
 q
zzzcmdbytes
 ;new $es,$et s $et="g:$es=0 Errzzzcmdbytes"
 if %crossClt s %ident=$e(%gZD,1,4),%gZD=$e(%gZD,10,$l(%gZD))
 s outStruct("dataPart")=%gZD x $$Action^Lib("s reslt="_outStruct("lineProc"))
 s %gD=$s(outStruct("fsize")'>(+$g(reslt)):"ok",$g(reslt)=0:"error:"_$zstatus,1:"1")
 if %crossClt,$i(%srvident) s %gD="I"_%ident_$tr($j(%srvident#10000,4)," ",0)_" "_%gD s %gD=$$ZZCVToul(%gD)
 i $d(%ARMLog) s ^mtempARMLog($j,%ARMLog,"3ZCMD")=$$gettime()_"<--result="_%gD_" "_+$g(reslt)
 q
Errzzzcmdbytes
 s $ec="" s %gD="error"_$zstatus
 q
zauth ; команда инициализации соединения
 n %gzl s %gzl=$p(%gZD," "),%gZD=$ze(%gZD,$l(%gzl)+2,$l(%gZD))
 ;s:$g(%ARMLog) ^mtempARMLog($j,%ARMLog,"6Auth1")=%gZD
 s %gD=$$InitSession(%gZD)
 ;s:$g(%ARMLog) ^mtempARMLog($j,%ARMLog,"6Auth2")=%gD
 q
zprot ; запрос протокола клиентом
 if %crossClt s %ident=$ze(%gZD,1,4),%gZD=$ze(%gZD,10,$l(%gZD))
 d wrgl s %gD=1 k %cont
 s %gD=$$ZZCVToul($$addIdent(%gD))
 q
 ;end----------commands

bfsizen(l)
 n n s n=l\256
 q $zCh(n,-n*256+l)

zcmd1(%GTM)
 ; %GTM(77)
 i '$F(%GTM," ") s %GTM=" s %GTM(77)="_%GTM_"()"
 e  d  ; формирование параметров метода
 . n m,i,l,z
 . s m=$P(%GTM," "),%GTM=$E(%GTM,$L(m)+2,$L(%GTM))
 . i $F(m,"&") s %GTM("p")="&"_$P(m,"&",2,$L(m,"&")),m=$P(m,"&")
 . s %GTM("p")=$G(%GTM("p"),"")
 . f i=1:1 q:%GTM=""  s l=$P(%GTM," "),z=$L(l),l=l/2 q:l'?1.N  s @("%gar"_i)=$E(%GTM,z+2,z+1+l),%GTM=$E(%GTM,z+l+3+$S(l:0,1:-1),$L(%GTM))
 . s %GTM=" s %GTM(77)="_m_"(" f i=1:1:i-1 s %GTM=%GTM_$S($F(%GTM("p"),"&"_$Tr($J(i,2)," ",0)):".",1:"")_"%gar"_i_","
 . s $E(%GTM,$L(%GTM))=")"

 s flgbr=(%gZC="zcmd1")&($G(%BrkOnEv)'="")&((%GTM[$G(%BrkOnEv))!($G(%BrkOnEv)="*"))
 s:$G(flgbr) %GTM=$E(%GTM,1,14)_"DEBUG^%Serenji("""_$E(%GTM,15,32000)_""","""_qARM("ClientIP")_""")"
 x $$Action^Lib(%GTM)
 s %GTM(77)=$$ZZCVToul($G(%GTM(77)))
 i '$L($G(%GTM("p"))) q %GTM(77)
 s %GTM(77)=$$bfsizen($zL(%GTM(77)))_%GTM(77)
 f %GTM(1)=2:1:$L(%GTM("p"),"&") s %GTM("r")=$$ZZCVToul(@("%gar"_(+$P(%GTM("p"),"&",%GTM(1))))),%GTM(77)=%GTM(77)_$$bfsizen($zL(%GTM("r")))_%GTM("r")
 q %GTM(77)
gettime()
 s %akfile="/proc/uptime" o %akfile:readonly u %akfile r %akutime u $p c %akfile
 s %utime=$p(%akutime," ")-%gUTIME,%gUTIME=%gUTIME+%utime
 q %utime
addlog(%str)
 i $d(%ARMLog) s ^mtempARMLog($j,%ARMLog,"4COMM")=$g(^mtempARMLog($j,%ARMLog,"4COMM"))_%str
 q
ZZCVTiul(%gtu) ; Конвертация из UTF-16 в кодировку базы
 i $zL(%gtu)#2 s %gtu=%gtu_$zch(0)
 ; новая версия (>GT.M V7.0) $zcvt() имеет обратный порядок параметров
 i $get(%ydbVer7) q $zcvt(%gtu,"UTF-16",$s($zchset="M":"CP1251",1:"UTF-8"))
 ; старая версия $zcvt() имеет проблемы с символом $c(152)
 n cp s cp=$s($zchset="M":"CP1251",1:"UTF-8")
 q:cp="UTF-8" $zcvt(%gtu,cp,"UTF-16")
 q:$zF(%gtu,$zCh(152,0))=0 $ZCVT(%gtu,cp,"UTF-16")
 n %gtu3,i s %gtu3="" f i=1:1:$zl(%gtu,$zch(152,0)) s %gtu3=%gtu3_$ZCVT($zpi(%gtu,$zch(152,0),i),cp,"UTF-16")_$zch(152)
 q $ze(%gtu3,1,$zl(%gtu3)-1)
ZZCVToul(%gzu) ; Конвертация из кодировки базы в UTF-16
 q:$g(%gzu)="" ""
 ; новая версия (>GT.M V7.0) $zcvt() имеет обратный порядок параметров
 i $get(%ydbVer7) q $ZCVT(%gzu,$s($zchset="M":"CP1251",1:"UTF-8"),"UTF-16")
 ; старая версия $zcvt() имеет проблемы с символом $c(152) и для непустых строк или числовых значений добавляет BOM - $C(255,254), который надо убрать.
 n %out,%tmp,%i,%in,cp s cp=$s($zchset="M":"CP1251",1:"UTF-8")
 i cp="UTF-8" d  q %out
 .s %out="" f %i=0:1 s %tmp=$e(%gzu,%i*8192+1,(%i+1)*8192) q:%tmp=""  s %in=$zcvt(%tmp,"UTF-16",cp) s %out=%out_$S($ZE(%in,1,2)=$ZCH(255,254):$ZE(%in,3,$ZL(%in)),1:%in)
 s %gzu1=$zf(%gzu,$zch(152)) i %gzu1=0 s %tmp=$ZCVT(%gzu,"UTF-16",cp) q $S($ze(%tmp,1,2)=$C(255,254):$ze(%tmp,3,$zl(%tmp)),1:%tmp)
 s %out="" f  s %tmp=$ZCVT($ze(%gzu,1,%gzu1-2),"UTF-16",cp)  s %out=%out_$S($ze(%tmp,1,2)=$C(255,254):$ze(%tmp,3,$zl(%tmp)),1:%tmp)_$S(($zl(%gzu)+2)=%gzu1:"",1:$zch(152,0)) s %gzu=$ze(%gzu,%gzu1,$zl(%gzu)),%gzu1=$zf(%gzu,$zch(152)) s:%gzu1=0 %gzu1=$zl(%gzu)+2 q:%gzu=""
 q %out
initLogging() ; включение внутреннего логгирования
 kill ^mtempARMLOG($job) set %ARMLog=1,^mtempARMLOG($job,%ARMLog)="begin" quit 1
stopLogging() ; выключение внутреннего логгирования
 kill %ARMLog quit 1
errcmd
 ; Вызывается из qmumps при завершении процесса (первоначально из-за вызова %ZSTOP)
 s ($EC,%gD)=""
 d JOB^%ZSTOP()
 if $d(%ARMLog) n x,i s x=$I(^Ve),^Ve($J,x)=$ZSTATUS_" "_$s($d(var):"var="_var,1:"") f i=1:1:$ZL s ^Ve($J,x,"st",i,"M")=$ST(i,"MCODE"),^Ve($J,x,"st",i,"P")=$ST(i,"PLACE"),^Ve($J,x,"st",i,"E")=$ST(i,"ECODE")
 q:$Q "" q

 ;*****************************************************************************
 ; *depricated* С версии 2.8 глобал протокола используется напрямую! (#326293)  Функции работы с протоколом. 
getRef(job) ; возвращает ссылку на глобал для хранения протокола
 s:$g(job)="" job=$j
 i '$d(^mtempqprot("P",job)) s ^mtempqprot("P",job)=$h
 q $n(^mtempqprot("P",job))
setRec(job,message) ; запись сообщения в протокол
 s:$g(job)="" job=$j
 i '$d(^mtempqprot("P",job)) s ^mtempqprot("P",job)=$h
 n messageId s messageId=$i(^mtempqprot("P",job,"M"))
 i $zchset="M" if $l(message)>500000 s ^mtempqprot("P",job,"M",messageId)=$e(message,1,500000),message=$e(message,500001,$l(message)),messageId=$i(^mtempqprot("P",job,"M"))
 s ^mtempqprot("P",job,"M",messageId)=message
 q messageId
readRec(job,messageId) ; чтение сообщения из протокола; Если индекс сообщения не передан, то добыча через $order(,"") + удаление из глобала
 s:$g(job)="" job=$j
 i $g(messageId)'="",$i(messageId) q $g(^mtempqprot("P",job,"M",messageId))
 n message 
 s messageId=$order(^mtempqprot("P",job,"M",""),1,message) q:messageId="" ""
 k ^mtempqprot("P",job,"M",messageId)
 q message 
delRec(job,messageId) ; удаление сообщения из протокола
 q:$g(messageId)="" 0
 k ^mtempqprot("P",$j,"M",messageId)
 q 1
 ; удалить весь протокол для job'а
kill(job)
 ; здесь хорошо бы вставить проверку возможности удаления; вызывается из %ZSTOP
 kill ^mtempqprot("P",job) quit 1
clear(job) ; полная очистка протокола
 s:$g(job)="" job=$j k ^mtempqprot("P",job) q 1
getPSaveRef(job,clear)
 s job=$g(job,$j) n ref s ref=$na(^qprotSave(job)) k:clear @ref
 q ref

 ;*******************************************************************
 ; процедура инициализации сессии
 ; 1. license checking (guid needs)
 ; 2. client version checking
 ; 3. jump to namespace (Cache only)
 ; 4. cleaning of protocol ^qprotstr(Job)
 ; returns 1 - success, 0;ErrorDescription - error
InitSession(init)
 n name,val,p,nSpacer,sc,i s sc=1
 s %srvident=0,%crossClt=0,%curJob=$j
 f i=1:1:$l(init,";")  s p=$p(init,";",i),name=$p(p,":"),val=$p(p,":",2) n @name s @name=val s qARM("init",name)=val
 s sc=$$checkLicense(GUID)
 i sc s sc=$$checkVer(Ver)
 i sc,'$$clear($job) s sc="0;Protocol was not cleared"
 q sc
checkLicense(GUID)
 q 1  ; license checking is switched off 20181121 @taketori
 ; i $g(GUID)="" q "0;Client GUID is empty. License checking is unavailable"
 ; q:$$Ver'>1.2 1
 ; i $$licServerPresent() n answ d &xgtmpty.xcpty(GUID,.answ) q answ
 ; ;e  q "0;There is no license checking server"
 ; q $$checkTempLic(GUID)
checkTempLic(GUID)
 n g,p,n,j s p=$na(^mtempLicense) i $g(@p)'=+$h k @p s @p=+$h
 s g="",n=0 f  s g=$o(@p@(g)) q:g=""  s j="" f  s j=$o(@p@(g,j)) q:j=""  s n=n+$zgetjpi(j,"isprocalive")
 i n<5 s @p@(GUID,$j)="" q 1
 q "0;There is no license checking server and temporary connections limit exceeded"
licServerPresent() ; *depricated* проверка наличия сервера лицензии для MBase
 s $zt="q 0"
 q:'$l($ztrnlnm("GTMXC_xgtmpty")) 0
 do &xgtmpty.xlic(.answ) q:$e(answ)=0 0
 q 1
checkVer(ver)
 i $g(ver)="" q "0;Version is empty. License checking is unavailable"
 i $p(ver,".")'<8,$p(ver,".",2)'<4 s %crossClt=1,noRtDecode=0
 e  s %crossClt=0 s noRtDecode=$s($p(ver,".",4)<9622:1,1:0)
 q 1
zu5(nspace,clear)
 ;s clear=$g(clear,1),nspace=$zcvt($g(nspace,$znspace),"U")
 ;n nspacer s nspacer=$zu(5,nspace) i nspacer'=nspace q 0
 i clear q $$clear($job)
 q 1