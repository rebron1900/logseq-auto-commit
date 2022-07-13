# logseq-auto-commit
auto sync logseq files
我目前正在使用的就是 Git 方案，该如何创建库之类的操作我就不再说了，社群和网上有很多资料，我这里单独说下我是怎么让 Git 实现多端（多个 window 间同步）同步，同时解决多端无脑同步的问题

目前 Github 上有两三个专门针对 Logseq 写的自动 Commit 工具，分别是

*   Logseq 官方的同步脚本：<https://github.com/logseq/git-auto>

*   热心网友写的： <https://github.com/CharlesChiuGit/Logseq-Git-Sync-101>

热心网友写的那个我之前一直出现各种莫名奇妙的问题导致无法提交，所以现在用的是第一个 Logseq 官方的自动提交脚本。

但是这两个脚本都有一个问题 —— 因为我平时有两个环境，一个公司一个家里。这就导致了我在公司写完笔记回去后在家里需要先进行一次手动的 pull 操作才能正常自动 Commit，这让我觉得巨麻烦，难道就不能判断一下 push 操作的结果，如果提示不成功就先做下 pull 的操作同步最新的库再开始自动提交？

所以我试着改动了一下官方脚本的代码，因为不懂 powershell 的脚本要怎么写，写了下面这段代码，但是一直无法执行。

```bash
# 如果带了push参数则进行push操作
if ($PushToServer) {
		# 获取gitpush的执行结果
        [string] $output = (&  git push $Server $Branch)
        # 因为如果本地库和远端库不一致git会提示你需要执行git pull操作，所以这里判断一下执行结果里面有没有git pull，如果有则执行git pull操作
        if($output.Contains("git pull")){
            git pull
       }
    }
```

我再 Logseq 的官方 QQ 群里问了一下，不过大佬们似乎没时间，所以我再 V2ex 上发了个帖子求教，运气不好很快就得到了解决方法，[moen](https://www.v2ex.com/member/moen) 大佬说：git 的输出是写到 stderr 的，所以得写成  `& git push $Server $Branch 2>&1` ，我一改果然成功了。

修改后的代码如下（文件名： `Start-GitAutoCommit.ps1`  ）：

```bash
# Usage:
#  git-auto ;; use current script dir as git dir, and Start-GitAutoCommitAnoPpush.
#  git-auto -d /path/to/your/note's/dir   ;; set git dir
#  git-auto -p ;; Start-GitAutoCommitAndPush
#  git-auto -s origin -p ;; set remote server
#  git-auto -b main -p ;; set git branch
#  git-auto -i 30 -p ;; set interval seconds
#  git-auto -o -p;; execute once

# parameters
param (
    [Alias('d')]
    [string] $Dir,
    [Alias('i')]
    [int] $Interval = 20,
    [Alias('p')]
    [switch] $PushToServer = $false,
    [Alias('o')]
    [switch] $Once = $false,
    [Alias('s')]
    [string] $Server,
    [Alias('b')]
    [string] $Branch
)

# if -Dir/-d specified
if ($Dir -ne "") {
    Set-Location $Dir
}

# if -Branch/-b specified
if ($Branch -eq "") {
    $Branch = (& git rev-parse --abbrev-ref HEAD)
}

function Start-GitAutoCommitAndPush {
    [string] $status = (& git status)
    if (!$status.Contains("working tree clean")) {
        git add .
        git commit -m "auto commit"
    }
    if ($PushToServer) {
        [string] $output = (&  git push $Server $Branch 2>&1)        
        if($output.Contains("git pull")){
            git pull
       }
    }
}

Get-Date

if ($Once) {
    Start-GitAutoCommitAndPush
}
else {
    while ($true) {
        Start-GitAutoCommitAndPush
        Start-Sleep -Seconds $Interval
    }
}
```

另外还写了一个作为调用入口的 bat 文件，因为这样我才能通过任务计划调用，你可能会问我为啥不直接用计划任务调用 ps1 文件？我只能告诉你我折腾过，但是失败了，我不会～。

文件名： `Auto-Commit.bat`  

```
    @echo off
    echo "DOCS PUSH BAT"

    echo "1. Move to working directory" 
    ::移动到你的logseq库文件夹内
    D:
    cd D:\developer\logseq
     
    echo "2. Start GitAutoCommit.ps1"

    ::执行powershell脚本，并设置远程分支和本地分支，并设置每30妙操作一次，并自动push
    PowerShell.exe -file Start-GitAutoCommit.ps1 -s origin -b main -i 30 -p
     
    echo "Auto Commit Start"
```

通过计划任务调用这个 bat 脚本就能实现开机自动后台运行这个脚本。

### 使用方法

1.  进入你的 Logseq 库

2.  创建一个名为 `Start-GitAutoCommit.ps1` 的文件，并把上面这个文件的代码复制粘粘贴进去

3.  创建一个名为 `Auto-Commit.bat` 的文件，并把上面这个文件的代码复制粘贴进去，并修改 `::移动到你的logseq库文件夹内` 后面的 `D:` `cd D:\developer\logseq` 为你的 logseq 库的路径

4.  运行 `Auto-Commit.bat` 即可

