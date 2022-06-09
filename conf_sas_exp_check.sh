#!/bin/bash


prev_conf_ver=`curl --silent -u <email>:<Confluence Personal Access Token> -X GET https://<subdomain>.atlassian.net/wiki/rest/api/content/<confluence article ID>?expand=body.storage,version | python3 -mjson.tool | grep number | cut -f2 -d ":" | cut -f1 -d","`

echo $prev_conf_ver

conf_ver=$((prev_conf_ver+1))

page_cont=`curl --silent -u <email>:<Confluence Personal Access Token> -X GET https://<subdomain>.atlassian.net/wiki/rest/api/content/<confluence article ID>?expand=body.storage | python3 -mjson.tool | grep body | cut -f2 -d ":"`

exp_dates=`echo ${page_cont%<h2>Description</h2>*} | tr -d '\\' | tr -d '"' | tr -d '{'`

 
echo $exp_dates | sed 's/<br\s\/>/\n/g' | sed 's/<p>//g' | sed 's/<\/p>//g' | sed 's/<time\sdatetime=//g' | sed 's/\s\/>//g' > /tmp/conflunce_temp

grep '\S' /tmp/conflunce_temp > /tmp/conflunce_temp_bk && mv /tmp/conflunce_temp_bk /tmp/conflunce_temp

unset taskstr
unset exprstr

while read line
do
	token=`echo $line | cut -f1 -d" "`
	ex_d=`echo $line | cut -f2 -d" "`
	
	ex_d_epoch=`date -d $ex_d +%s`
	curr_epoch=`date +%s`
	epoch_diff=$((ex_d_epoch - curr_epoch))
	
	exprstr+="${token} <time datetime=\\\"${ex_d}\\\" /> <br />"

	#Checking if expiry is in a week or so
	if [ $epoch_diff -le 604800 ];then
		taskstr+="<ac:task><ac:task-id>4</ac:task-id><ac:task-status>incomplete</ac:task-status><ac:task-body><span class=\\\"placeholder-inline-tasks\\\"><ac:link><ri:user ri:userkey=\\\"<Confluence user key>\\\" /></ac:link> Please renew this SAS Token: ${token} by <time datetime=\\\"${ex_d}\\\" /></span></ac:task-body></ac:task>"
	fi
	
done < /tmp/conflunce_temp

if [[ ! -z "$taskstr" ]];then
	put_req_body="{\"id\":\"13707160393\",\"type\":\"page\",\"title\":\"Azure SAS token rotation\",\"body\":{\"storage\":{\"value\":\"<p>${exprstr}</p><h2>Description</h2><p>Whole idea of this article is to rotate Azure SAS Tokens when necessary.</p><h2>Renewal Tasks</h2><ac:task-list>\n${taskstr}</ac:task-list>\",\"representation\":\"storage\"}},\"version\":{\"number\":\"${conf_ver}\"}}"
	curl --silent -u <email>:<Confluence Personal Access Token> -X PUT -H 'Content-Type: application/json' -d "${put_req_body}" https://<subdomain>.atlassian.net/wiki/rest/api/content/<confluence article ID> | python3 -mjson.tool
fi


unset prev_conf_ver
unset conf_ver
unset page_cont
unset exp_dates
