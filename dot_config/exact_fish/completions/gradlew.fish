# gradlew: 项目根目录下 Gradle Wrapper 的补全
# 选项部分移植自 fish 自带的 gradle.fish 补全
# See: https://github.com/fish-shell/fish-shell/blob/master/share/completions/gradle.fish

function __fish_gradlew_find_root -d "从当前目录向上查找 gradlew 所在的构建根目录"
    set -l dir $PWD
    while true
        if test -x $dir/gradlew
            echo $dir
            return 0
        end
        set -l parent (path dirname $dir)
        test $parent = $dir; and return 1
        set dir $parent
    end
end

function __fish_gradlew_cache_name -d "把构建根目录映射为合法的缓存文件名"
    string replace -ar '[^\w.-]' _ -- "$argv[1]"
end

# 项目外只补全不需要构建的项目内的内置任务
function __fish_gradlew_get_default_task_completion -d "列出不依赖项目的内置任务"
    __fish_gradlew_find_root >/dev/null; and return

    printf '%s\t%s\n' \
        buildEnvironment "Display buildscript dependencies" \
        components "Display components" \
        dependencies "Display dependencies" \
        dependencyInsight "Display insight of a given dependency" \
        dependentComponents "Display the dependent components" \
        help "Display help message" \
        init "Initialize new Gradle project" \
        model "Display configuration model" \
        projects "Display sub-projects" \
        properties "Display properties" \
        tasks "Display tasks" \
        wrapper "Generate Gradle wrapper files"
end

# 项目内运行 gradlew tasks --all 获取任务，结果按目录缓存
function __fish_gradlew_get_project_tasks -d "获取项目任务（带缓存）"
    set -l root (__fish_gradlew_find_root)
    or return

    set -l cache_dir (__fish_make_cache_dir gradlew-completions)
    or return
    set -l prefix $cache_dir/(__fish_gradlew_cache_name "$root")
    set -l signature_file $prefix.signature
    set -l tasks_file $prefix.tasks

    # 构建脚本未修改且缓存不超过一周时直接复用
    set -l signature (command find $root -maxdepth 3 -type f \
        \( -name '*.gradle' -o -name '*.gradle.kts' -o -name 'gradle.properties' \) 2>/dev/null | command sort)
    if test -s $tasks_file; and test -n "$(command find $signature_file -mmin -10080)"
        if test "$signature" = "$(command cat $signature_file 2>/dev/null)"
            command cat $tasks_file
            return
        end
    end

    set -l tasks (command $root/gradlew -q tasks --all 2>/dev/null | string match --regex '^\s*(?:\([^)]*\)\s*)?(?![->])[\w:.-]+\s+-\s+.*$' |
        string replace -r '^\s*(?:\([^)]*\)\s*)?(?!.* - )' '' | string replace -r '(?<=[\w:.-]) - (?=.)' \t)
    if not set -q tasks[1]
        # 构建脚本执行失败时不写缓存，下次补全时重试
        return
    end

    printf '%s\n' $tasks >$tasks_file
    printf '%s\n' "$signature" >$signature_file
    printf '%s\n' $tasks
end

function __fish_gradlew_erase_cache -d "删除当前项目的任务缓存"
    set -l root (__fish_gradlew_find_root)
    or return 1
    set -l cache_dir (__fish_make_cache_dir gradlew-completions)
    or return 1
    command rm -f $cache_dir/(__fish_gradlew_cache_name "$root").*
end

function __fish_gradlew_reload_tasks -d "忽略缓存，重新生成任务补全"
    __fish_gradlew_erase_cache
    commandline -f repaint
end

##############################
# Configure Tasks Completion #
##############################

complete --command gradlew --exclusive --condition 'not __fish_gradlew_find_root >/dev/null' \
    --arguments '(__fish_gradlew_get_default_task_completion)'

complete --command gradlew --exclusive --condition '__fish_gradlew_find_root >/dev/null' \
    --arguments '(__fish_gradlew_get_project_tasks)'

###############################
# Configure Option Completion #
###############################

function __fish_gradlew_get_console_completion
    printf '%s\t%s\n' \
        auto "Use 'rich' in console otherwise 'plain'" \
        plain "Disable color and rich output" \
        rich "Enable color and rich output" \
        verbose "Enable color, rich output, output task names and outcomes at the lifecycle log level"
end

function __fish_gradlew_get_property_completion
    printf '%s\t%s\n' \
        "org.gradle.cache.reserved.mb" "Reserve Gradle Daemon memory for operations" \
        "org.gradle.caching" "Enable Gradle build cache" \
        "org.gradle.console" "Set type of console output to generate (plain, auto, rich, verbose)" \
        "org.gradle.daemon.debug" "Enable debug Gradle Daemon" \
        "org.gradle.daemon.idletimeout" "Kill Gradle Daemon after" \
        "org.gradle.debug" "Enable debug Gradle Client" \
        "org.gradle.jvmargs" "Set JVM arguments" \
        "org.gradle.java.home" "Set JDK home dir" \
        "org.gradle.logging.level" "Set default Gradle log level (quiet, warn, lifecycle, info, debug)" \
        "org.gradle.parallel" "Enable parallel project builds (incubating)" \
        "org.gradle.priority" "Set priority for Gradle worker processes (low, normal)" \
        "org.gradle.warning.mode" "Set types of warnings to log (all, summary, fail, none)" \
        "org.gradle.workers.max" "Set the number of workers Gradle is allowed to use"
end

function __fish_gradlew_get_priority_completion
    printf '%s\t%s\n' \
        normal "Default process priority" \
        low "Low process priority"
end

function __fish_gradlew_get_warning_mode_completion
    printf '%s\t%s\n' \
        all "Log all warnings" \
        summary "Suppress all warnings, log a summary at the end" \
        fail "Log all warnings and fail the build if there are any" \
        none "Suppress all warnings, including the summary at the end"
end

# 以下选项补全移植自 fish 自带的 gradle.fish
complete --command gradlew \
    --long-option help \
    --short-option h --short-option '?' \
    --description 'Show this help message'
complete --command gradlew \
    --long-option no-rebuild \
    --short-option a \
    --description 'Do not rebuild project dependencies'
complete --command gradlew \
    --long-option build-cache \
    --description 'Enable Gradle build cache'
complete --command gradlew \
    --long-option configure-on-demand \
    --description 'Configure necessary projects only [incubating]'
complete --command gradlew --require-parameter --no-files \
    --long-option console \
    --exclusive \
    --description 'Specify type of console output' \
    --arguments "(__fish_gradlew_get_console_completion)"
complete --command gradlew \
    --long-option continue \
    --description 'Continue task execution after task failures'
complete --command gradlew --require-parameter \
    --long-option system-prop \
    --short-option D \
    --exclusive \
    --description 'Set system property of the JVM (e.g. -Dmyprop=myvalue)' \
    --arguments "(__fish_gradlew_get_property_completion)"
complete --command gradlew \
    --long-option debug \
    --short-option d \
    --description 'Log in debug mode (incl. normal stacktrace)'
complete --command gradlew \
    --long-option daemon \
    --description 'Uses Gradle Daemon'
complete --command gradlew \
    --long-option foreground \
    --description 'Start Gradle Daemon in foreground'
complete --command gradlew \
    --long-option gradle-user-home \
    --short-option g \
    --force-files \
    --require-parameter \
    --description 'Specify gradle user home directory'
complete --command gradlew \
    --long-option init-script \
    --short-option I \
    --force-files \
    --require-parameter \
    --description 'Specify initialization script'
complete --command gradlew \
    --long-option info \
    --short-option i \
    --description 'Info log level'
complete --command gradlew \
    --long-option include-build \
    --force-files \
    --require-parameter \
    --description 'Include specified build in composite'
complete --command gradlew \
    --long-option dry-run \
    --short-option m \
    --description 'Run builds with all task actions disabled'
complete --command gradlew \
    --long-option max-workers \
    --exclusive \
    --description 'Configure number of concurrent workers'
complete --command gradlew \
    --long-option no-build-cache \
    --description 'Disable Gradle build cache'
complete --command gradlew \
    --long-option no-configure-on-demand \
    --description 'Disable use of configuration on demand [incubating]'
complete --command gradlew \
    --long-option no-daemon \
    --description 'Disable Gradle daemon'
complete --command gradlew \
    --long-option no-parallel \
    --description 'Disable parallel execution'
complete --command gradlew \
    --long-option no-scan \
    --description 'Disable creation of build scan'
complete --command gradlew \
    --long-option offline \
    --description 'Execute build without accessing network resources'
complete --command gradlew \
    --long-option project-prop \
    --short-option P \
    --exclusive \
    --description 'Set project property for build script (e.g. -Pmyprop=myvalue)'
complete --command gradlew \
    --long-option project-dir \
    --short-option p \
    --force-files \
    --require-parameter \
    --description 'Specify start directory for Gradle'
complete --command gradlew \
    --long-option parallel \
    --description 'Build projects in parallel'
complete --command gradlew --require-parameter --no-files \
    --long-option priority \
    --exclusive \
    --description 'Specify scheduling priority for the Gradle daemon and all processes launched by it' \
    --arguments "(__fish_gradlew_get_priority_completion)"
complete --command gradlew \
    --long-option profile \
    --description 'Profile build execution time and generate report'
complete --command gradlew \
    --long-option project-cache-dir \
    --force-files \
    --require-parameter \
    --description 'Specify cache directory'
complete --command gradlew \
    --long-option quiet \
    --short-option q \
    --description 'Error log level'
complete --command gradlew \
    --long-option refresh-dependencies \
    --description 'Refresh dependencies state'
complete --command gradlew \
    --long-option rerun-tasks \
    --description 'Ignore previously cached task results'
complete --command gradlew \
    --long-option full-stacktrace \
    --short-option S \
    --description 'Print out full stacktrace'
complete --command gradlew \
    --long-option stacktrace \
    --short-option s \
    --description 'Print out stacktrace'
complete --command gradlew \
    --long-option scan \
    --description 'Creates build scan'
complete --command gradlew \
    --long-option status \
    --description 'Show status of Gradle Daemon(s)'
complete --command gradlew \
    --long-option stop \
    --description 'Stop Gradle Daemon(s)'
complete --command gradlew \
    --long-option continuous \
    --short-option t \
    --description 'Enable continuous build'
complete --command gradlew \
    --long-option exclude-task \
    --short-option x \
    --require-parameter \
    --description 'Specify a task to exclude from execution'
complete --command gradlew \
    --long-option update-locks \
    --require-parameter \
    --description 'Perform a partial update of the dependency lock [incubating]'
complete --command gradlew \
    --long-option version \
    --short-option v \
    --description 'Print version info.'
complete --command gradlew \
    --long-option warn \
    --short-option w \
    --description 'Warn log level'
complete --command gradlew --require-parameter --no-files \
    --long-option warning-mode \
    --description 'Specify warn mode' \
    --arguments "(__fish_gradlew_get_warning_mode_completion)"
complete --command gradlew \
    --long-option write-locks \
    --description 'Persists dependency resolution for locked configurations [incubating]'

# 隐藏选项：清除任务缓存后重新补全
complete --command gradlew --long-option __gradlew-reload-tasks \
    --description 'Clear the gradlew task cache and reload'
