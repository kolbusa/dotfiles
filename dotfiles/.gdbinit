set history save
set print pretty
set startup-with-shell off
set debuginfod enabled off
# source ~/.gdb-dashboard

define bardecode
    print /x $arg0
    set $bd_val = *(@shared unsigned long long *)$arg0
    eval "shell ~/work/tools/bardecode 0x%llx", $bd_val
end

define tmadecode
    print /x $arg0 $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7
end
