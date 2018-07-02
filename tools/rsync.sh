#!/usr/bin/expect

#暂时没有使用

set timeout -1
set host [lindex $argv 0]
set username root
set password 123456
set src_file [lindex $argv 1]
set dest_file [lindex $argv 2]

spawn rsync -av $username@$host:$src_file $dest_file
 expect {
     "(yes/no)?"
         {
             send "yes\n"
             expect "*assword:" { send "$password\n"}
         }
     "*assword:"
         {
             send "$password\n"
         }
     }
# expect "100%"
 expect eof
