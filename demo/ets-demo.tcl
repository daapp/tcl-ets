tcl::tm::path add ../lib

package require ets


proc showResponse {tid response} {
    puts "$tid :: $response"
}

puts "create ets"
ets e -name hello -command showResponse
puts [e id]
puts "create table tab1"
e new tab1
puts "insert key1"
e insert tab1 key1 value1
e insert tab1 key2 value2
puts "lookup"
e lookup tab1 key2
e lookup tab1 key1
e lookup tab2 k
e lookup tab1 key*
puts "delete"
e delete tab1 key1
e lookup tab1 key*

puts "wait ..."
vwait forever
