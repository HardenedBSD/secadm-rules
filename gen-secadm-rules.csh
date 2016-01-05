#!/usr/bin/env csh 
#
# secadm version 0.3+ rule builder
#

if ( $euser != "root" ) then
	echo "fail...this script needs root user"
	exit 1
endif

set _rules_file = `mktemp`

if ( ! -f ${_rules_file} ) then
	echo "fail...temp file creation failed"
	exit 1
endif
	
set secadm_rules =  "/usr/local/etc/secadm.rules"

if ( ! -e ${secadm_rules} ) then
	echo "fail...please create the secadm rule file at ${secadm_rules}"
	exit 1
endif


cat >> ${_rules_file}<<EOF
secadm {
EOF

foreach i ( *.rule )
	#test that every binary in the rule file exists
	#or secadm will not validate correctly
	set _test = 0
	set _bin = `sed -n '/path/s/.*\"\(.*\)\",*/\1/p' $i`

	foreach j ( ${_bin}) 
		if ( -e ${j} && ! -l ${j} ) then
			echo "added ${j} rule to ${secadm_rules}"
		else
			echo "skipped ${j}, program does not exists on the system or is a link to another program"
			set _test = 1
		endif
	end
	if ( ${_test} == 0 ) then
		sed 's/^/		/g' ${i} >> ${_rules_file}
	else
		echo "skipped ${i} rule file as some programs do not exist on the system"
	endif
end

cat >> ${_rules_file}<<EOF
	
}
EOF

echo
echo "--------------------------------------------------"
cat ${_rules_file}
echo "--------------------------------------------------"

again:
printf 'enter \"yes\" if the rules are okay and change the current ruleset or \"no\" when not: '
set _in = $<
if ( ${_in} != "yes" && ${_in} != "no" ) then
	goto again
endif

if ( ${_in} == "yes" ) then
	chflags noschg ${secadm_rules}
	cp ${_rules_file} ${secadm_rules}
	chown root:wheel ${secadm_rules}
	chmod 0500 ${secadm_rules}
	chflags schg ${secadm_rules}
	
	set _test = `secadm validate ${secadm_rules}`
	if ($status != 0) then
		echo "secadm rules saved, but failed validation"
	else
		secadm load ${secadm_rules}
	endif
endif

rm ${_rules_file}
