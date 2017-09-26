package require snit
package require connectedThread

snit::type ets {
    option -name -default "" -readonly 1
    option -type -default "dict" -readonly 1
    option -command -default ""

    component etsCmd

    constructor {args} {
        $self configurelist $args
        set etsCmd [connectedThread ${self}_ets {
            set storage [dict create]
            while 1 {
                lassign [thread::receive] tid data
                set rest [lassign $data action]
                switch -- $action {

                    new {
                        # $ets new tabName
                        set rest [lassign $rest table]
                        dict set storage $table {}
                        thread::send [list ok]
                    }

                    insert {
                        # $ets insert tabName key value
                        set rest [lassign $rest table key value]
                        dict set storage $table $key $value
                        thread::send [list ok]
                    }

                    lookup {
                        # $ets lookup tabName key
                        set rest [lassign $rest table key]
                        if {[dict exists $storage $table]} {
                            thread::send [list ok [dict filter [dict get $storage $table] key $key]]
                        } else {
                            thread::send [list error "$table not found"]
                        }
                    }

                    default {
                        thread::send [list error "invalid action \"$action\" $rest"]
                    }
                }
            }
        }]
        $etsCmd readable [list apply {{command ets} {
            uplevel #0 $command [$ets receive]
        }} $options(-command) $etsCmd]
    }

    method new {tab} {
        $etsCmd send [list new $tab]
    }

    method insert {tab key value} {
        $etsCmd send [list insert $tab $key $value]
    }

    method lookup {tab key} {
        $etsCmd send [list lookup $tab $key]
    }

    delegate method id to etsCmd
}


if 1 {
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

    puts "wait ..."
    vwait forever
}
