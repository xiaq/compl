# This completion script is written according to the output of `go help` and
# `go help <command>` of Go 1.9.

fn spaces [n]{
    repeat $n ' ' | joins ''
}

fn cand [text desc]{
    edit:complex-candidate $text &display-suffix=' '(spaces (- 11 (wcswidth $text)))$desc
}

'&build-flags' = (constantly (
    cand -a "force rebuilding of packages that are already up-to-date"
    cand -n "print the commands but do not run them"
    cand -p "the number of programs that can be run in parallel"
    cand -race "enable data race detection"
    cand -msan "enable interoperation with memory sanitizer"
    cand -v "print the names of packages as they are compiled"
    cand -work "print the name of the temporary work directory and do not delete it when exiting"
    cand -x "print the commands"
    cand -asmflags "arguments to pass on each go tool asm invocation"
    cand -buildmode "build mode to use. See 'go help buildmode' for more"
    cand -compiler "name of compiler to use, as in runtime.Compiler (gccgo or gc)"
    cand -gccgoflags "arguments to pass on each gccgo compiler/linker invocation"
    cand -gcflags "arguments to pass on each go tool compile invocation"
    cand -installsuffix "a suffix to use in the name of the package installation directory"
    cand -ldflags "arguments to pass on each go tool link invocation"
    cand -linkshared "link against shared libraries previously created with -buildmode=shared"
    cand -pkgdir "install and load all packages from dir instead of the usual locations"
    cand -tags "a space-separated list of build tags to consider satisfied during the build"
    cand -toolexec "a program to use to invoke toolchain programs like vet and asm"
))

fn go-files [f]{
    put (path-dir $f)/*.go
}

fn pick-dirs {
    each [x]{ if (-is-dir $x) { put $x/ } }
}

-go-path-out-cache = ''
fn -go-paths {
    if (eq $E:GOPATH '') {
        if (eq $-go-path-out-cache '') {
            -go-path-out-cache = (go env GOPATH | slurp)
        }
        splits : $-go-path-out-cache
    } else {
        splits : $E:GOPATH
    }
}

fn pkgs [f]{
    if (has-prefix $f .) {
        put (path-dir $f)/* | pick-dirs
    } else {
        dir = (path-dir $f)/
        if (eq $dir ./) {
            dir = ''
        }
        # XXX: Uses $pwd, not concurrency-safe.
        for go-src [(-go-paths)/src] {
            pwd=$go-src {
                put $dir* | pick-dirs
            }
        }
    }
}

cached-env-vars = ''
fn env-vars {
    if (eq $cached-env-vars '') {
        cached-env-vars = [(keys (go env -json | from-json))]
    }
    explode $cached-env-vars
}

cached-tools = ''
fn tools {
    if (eq $cached-tools '') {
        cached-tools = [(go tool)]
    }
    explode $cached-tools
}

subcmd = [
    &build=[@args]{
        build-flags
        cand -o "write the resulting executable or object to the named output file"
        cand -i "install the packages that are dependencies of the target"

        pkgs $args[-1]
    }

    &clean=[@args]{
        build-flags
        cand -i "remove the corresponding installed archive or binary (what 'go install' would create)"
        cand -n "print the remove commands it would execute, but not run them"
        cand -r "be applied recursively to all the dependencies of the packages named by the import paths"
        cand -x "print remove commands as it executes them"
    }

    &doc=[@args]{
        cand -c 'Respect case when matching symbols'
        cand -cmd 'Treat a command (package main) like a regular package'
        cand -u 'Show documentation for unexported as well as exported symbols, methods, and fields'

        pkgs $args[-1]
    }

    &env=[@args]{
        cand -json 'prints the environment in JSON format instead of as a shell script'
        env-vars
    }

    &bug=[@args]{
        # This subcommand takes no arguments.
    }

    &fix=[@args]{
        pkgs $args[-1]
    }

    &fmt=[@args]{
        cand -n "print commands that would be executed"
        cand -x "print commands as they are executed"

        pkgs $args[-1]
    }

    &generate=[@args]{
        cand -run "a regular expression to select directives"
        build-flags

        go-files $args[-1]
        pkgs $args[-1]
    }

    &get=[@args]{
        cand -d "stop after downloading the packages; that is, it instructs get not to install the packages"
        cand -f "force get -u not to verify that each package has been checked out from the source control repository implied by its import path"
        cand -fix "run the fix tool on the downloaded packages before resolving dependencies or building the code"
        cand -insecure "permits fetching from repositories and resolving custom domains using insecure schemes such as HTTP. Use with caution"
        cand -t "also download the packages required to build the tests for the specified packages"
        cand -u "use the network to update the named packages and their dependencies"
        build-flags

        pkgs $args[-1]
    }

    &install=[@args]{
        build-flags

        pkgs $args[-1]
    }

    &list=[@args]{
        build-flags
        cand -f "specify an alternate format for the list, using the syntax of package template"
        cand -json "cause the package data to be printed in JSON format instead of using the template format"
        cand -e "change the handling of erroneous packages, those that cannot be found or are malformed"

        pkgs $args[-1]
    }

    &run=[@args]{
        cand -exec "invoke the binary using a program"
        build-flags

        go-files $args[-1]
    }

    &test=[@args]{
        cand -args "Pass the remainder of the command line (everything after -args) to the test binary, uninterpreted and unchanged"
        cand -c "Compile the test binary to pkg.test but do not run it"
        cand -exec "Run the test binary using a program"
        cand -i "Install packages that are dependencies of the test. Do not run the test"
        cand -o file "Compile the test binary to the named file. The test still runs (unless -c or -i is specified)"
        build-flags

        pkgs $args[-1]
    }

    &tool=[@args]{
        cand -n "print the command that would be executed but not execute it"

        tools
    }

    &version=[@args]{
        # This subcommand takes no arguments.
    }

    &vet=[@args]{
        cand -n "print commands that would be executed"
        cand -x "print commands as they are executed"
        build-flags

        pkgs $args[-1]
    }
]

fn compl [@words]{
    n = (count $words)
    if (== $n 2) {
        keys $subcmd
    } elif (> $n 2) {
        $subcmd[$words[1]] (explode $words[2:])
    }
}

edit:arg-completer[go] = $&compl
