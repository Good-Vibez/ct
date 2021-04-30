# vim: et ts=2 sw=2
function ng
  function ngui
    if ! set -q __ng__ui__enter
      set -g __ng__ui__enter
      if ng "$argv"
        set -e __ng__ui__enter
      else
        set -e __ng__ui__enter
        return 1
      end
    end
  end

  if false
    false
  else if test "$argv[1]" = "ui::col"
    set -e argv[1]
    set --local fmt (printf '[ \x1b[38;5;%sm%%s\x1b[m ]' "$argv[1]")
    set -e argv[1]
    printf $fmt "$argv"
  else if test "$argv[1]" = "ui::end"
    printf '\n'
  else if test "$argv[1]" = "ui::report:1"
    set -e argv[1]
    ng ui::col 112 "$argv"
    ng ui::end
  else if test "$argv[1]" = "ui::report:0"
    set -e argv[1]
    ng ui::col 111 "$argv"
    ng ui::end
  else if test "$argv[1]" = "ui::warn"
    set -e argv[1]
    ng ui::col 105 "$argv"
    ng ui::end
  else if test "$argv[1]" = "ui::failxplain"
    set -e argv[1]
    ng ui::col 99 "$argv"
    ng ui::end
  else if test "$argv[1]" = "ui::sem:shadow"
    set -e argv[1]
    ng ui::col 240 "$argv"
  else if test "$argv[1]" = "ui::sem:srv"
    set -e argv[1]
    ng ui::col 116 "$argv"
    ng ui::end
  else if test "$argv[1]" = "ui::sem:installing"
    set -e argv[1]
    ng ui::col 122 "$argv"
  else if test "$argv[1]" = "ui::process_item"
    set -e argv[1]
    ng ui::col 203 " ===> "
    ng ui::col 204 "$argv"
    ng ui::end
  else if test "$argv[1]" = "ui::note_su"
    set -e argv[1]
    ng ui::col 212 "sudo:: $argv"
    ng ui::end
  else if test "$argv[1]" = "ui::section"
    set -e argv[1]
    echo
    ng ui::col 198 =====
    ng ui::col 192 "$argv"
    ng ui::col 198 =====
    ng ui::end
  else if test "$argv[1]" = "ui::data"
    set -e argv[1]
    ng ui::col 109 "$argv"
    ng ui::end
  else if test "$argv[1]" = "config:path"
    printf '%s' "/etc/"(ng srv:raw)
  else if test "$argv[1]" = "config:path.local"
    printf '%s' ".local/etc/"(ng srv:raw)
  else if test "$argv[1]" = "config:list"
    find (ng config:path.local) -type f -printf '%P\000'
  else if test "$argv[1]" = "config:test"
    for item in (ng config:list | string split0)
      if ! ng test:installed {(ng config:path),(ng config:path.local)}/$item
        ng ui::warn NOT_INSTALLED $item
        return 1
      end
    end
  else if test "$argv[1]" = "config:"
    if ng config:test
      ng ui::report:1 CONFIGURED
    else
      ng ui::report:0 UNCONFIGURED
    end
  else if test "$argv[1]" = "config."
    for item in (ng config:list | string split0)
      if ng meta::loud:test
        ng ui::process_item $item
      end
      ng install:: {(ng config:path),(ng config:path.local)}/$item
    end
  else if test "$argv[1]" = "config-"
    for item in (ng config:list | string split0)
      if ng meta::loud:test
        ng ui::process_item $item
      end
      ng uninstall:: (ng config:path)/$item
    end
  else if test "$argv[1]" = "install_paths"
    printf '%s\n' {.local,}/etc/(ng srv:raw)/ #(ng srv:raw).conf
  else if test "$argv[1]" = "install"
    ng install_paths | xargs echo sudo cp -rv
    ng stop
    ng kill
    ng clean
    ng reload
  else if test "$argv[1]" = "reload"
    systemctl daemon-reload
  else if test "$argv[1]" = "sreload"
    systemctl reload (ng srv:raw)
  else if test "$argv[1]" = "relart"
    ng reload
    ng restart
  else if test "$argv[1]" = "relinstall"
    ng install
    ng relart
  else if test "$argv[1]" = "clean"
    sudo systemctl clean (ng srv:raw)
  else if test "$argv[1]" = "log"
    set -e argv[1]
    journalctl -u (ng srv:raw) "$argv"
  else if test "$argv[1]" = "reload:"
    ng ui::sem:installing Reloading...
    source .local/etc/fish/functions/ng.fish
    ng ui::report:1 OK
  else if test "$argv[1]" = "socket:activate"
    sudo mv -v /usr/local/lib/systemd/system/(ng srv:raw).socket{.null,}
  else if test "$argv[1]" = "socket:deactivate"
    sudo mv -v /usr/local/lib/systemd/system/(ng srv:raw).socket{,.null}
  else if test "$argv[1]" = "socket:activ"
    if test -r /usr/local/lib/systemd/system/(ng srv:raw).socket
      ng ui::report:1 ACTIVE
    else
      ng ui::report:0 INACTIVE
    end
  else if test "$argv[1]" = "s"
    ng status | cat
  else if test "$argv[1]" = "srv:raw"
    if ! set -q ng_service
      set -g ng_service nginx
    end
    printf '%s' $ng_service
  else if test "$argv[1]" = "srv:"
    ng ui::sem:srv (ng srv:raw)
  else if test "$argv[1]" = "srv:="
    set -e argv[1]
    set ng_service "$argv[1]"
    ng srv:
  else if test "$argv[1]" = "sd_comp:raw"
    if ! set -q sd_comp
      set -g sd_comp system
    end
    printf '%s' $sd_comp
  else if test "$argv[1]" = "sd_comp:"
    ng ui::sem:srv (ng sd_comp:raw)
  else if test "$argv[1]" = "sd_comp:="
    set -e argv[1]
    set sd_comp "$argv[1]"
    ng sd_comp:
  else if test "$argv[1]" = "sd_unit_scope:raw"
    if ! set -q sd_unit_scope
      set -g sd_unit_scope user
    end
    printf '%s' $sd_unit_scope
  else if test "$argv[1]" = "sd_unit_scope:"
    ng ui::sem:srv (ng sd_unit_scope:raw)
  else if test "$argv[1]" = "sd_unit_scope:="
    set -e argv[1]
    set sd_unit_scope "$argv[1]"
    ng sd_unit_scope:
  else if test "$argv[1]" = "sd_unit_type:raw"
    if ! set -q sd_unit_type
      set -g sd_unit_type service
    end
    printf '%s' $sd_unit_type
  else if test "$argv[1]" = "sd_unit_type:"
    ng ui::sem:srv (ng sd_unit_type:raw)
  else if test "$argv[1]" = "sd_unit_type:="
    set -e argv[1]
    set sd_unit_type "$argv[1]"
    ng sd_unit_type:
  else if test "$argv[1]" = "install:path"
    printf '%s/%s/%s.%s' "/usr/local/lib/systemd" (ng sd_unit_scope:raw) (ng srv:raw) (ng sd_unit_type:raw)
  else if test "$argv[1]" = "install:path.local"
    printf '%s/%s/%s.%s' (pwd)"/.local/etc/systemd" (ng sd_unit_scope:raw) (ng srv:raw) (ng sd_unit_type:raw)
  else if test "$argv[1]" = "sum::stdin"
    openssl sha256 -r | sd '^(.{64}).*' '$1'
  else if test "$argv[1]" = "test:installed"
    set -e argv[1]

    set --local dst "$argv[1]"
    set --local src $argv[2]
    set -e argv[1..2]

    if ! test -r $dst
      if ng meta::loud:test
        ng ui::failxplain "Not readable: $dst"
      end
      return 1
    end
    set --local sum_dst (cat $dst | ng sum::stdin 2>/dev/null)
    set --local sum_src (cat $src | ng sum::stdin 2>/dev/null)
    if ! test $sum_src = $sum_dst
      if ng meta::loud:test
        ng ui::failxplain "Badsums: $sum_dst != $sum_src"
      end
      return 1
    end
    if ng meta::loud:test
      ng ui::sem:shadow "🔒$sum_src"
      ng ui::end
    end
  else if test "$argv[1]" = "install::"
    set -e argv[1]

    set --local dst "$argv[1]"
    set --local src $argv[2]
    set -e argv[1..2]

    if ng meta::loud:test
      ng ui::sem:shadow "$src -> $dst"
      ng ui::end
    end
    if ng test:installed $src $dst && ng meta::loud:test
      ng ui::warn "RE_INSTALLING $src"
    end
    if test (string sub -s 1 -e 1 $dst) = "/"
      if ng meta::loud:test
        ng ui::note_su $dst
      end
      sudo mkdir -pv (dirname $dst)
      sudo cp $src $dst
    else
      cp $src $dst
    end
  else if test "$argv[1]" = "uninstall::"
    set -e argv[1]

    set --local dst "$argv[1]"
    set --local src $argv[2]
    set -e argv[1..2]

    if ng meta::loud:test
      ng ui::sem:shadow "🛃 $dst"
      ng ui::end
    end
    if test (string sub -s 1 -e 1 $dst) = "/"
      if ng meta::loud:test
        ng ui::note_su $dst
      end
      sudo rm -v $dst
    else
      rm -v $dst
    end
  else if test "$argv[1]" = "install:test"
    ng test:installed (ng install:path) (ng install:path.local)
  else if test "$argv[1]" = "install:"
    if ng install:test
      ng ui::report:1 (ng srv:raw) INSTALLED
    else
      ng ui::report:0 (ng srv:raw) NOT_INSTALLED
    end
  else if test "$argv[1]" = "install."
    if ng install:test
      ng ui::warn (ng srv:raw) REINSTALLING
    end
    ng ui::sem:installing (ng srv:raw) Installing...
    sudo mkdir -pv (dirname (ng install:path))
    sudo cp -v (ng install:path.local) (ng install:path)
    ng ui::report:1 OK
  else if test "$argv[1]" = "install-"
    if ! ng install:test
      ng ui::warn (ng srv:raw) GHOST_UNINSTALLING
    end
    ng ui::sem:installing (ng srv:raw) Uninstalling...
    sudo rm -rvf (ng install:path)
    ng ui::report:0 DEAD-OK
  else if test "$argv[1]" = "meta::loud:test"
    set -q __ng__meta__loud
  else if test "$argv[1]" = "meta::loud."
    set -g __ng__meta__loud
    ngui meta::loud:
  else if test "$argv[1]" = "meta::loud-"
    set -e __ng__meta__loud
    ngui meta::loud:
  else if test "$argv[1]" = "meta::loud:"
    if ng meta::loud:test
      ng ui::report:1 LOUD
    else
      ng ui::report:0 discreet
    end
  else if test "$argv[1]" = "report:"
    ng ui::section CONFIG
    printf 'sd component  '; ng sd_comp:
    printf 'sd unit scope '; ng sd_unit_scope:
    printf 'sd unit type  '; ng sd_unit_type:
    printf 'unit          '; ng install:
    printf 'socket        '; ng socket:activ
    printf 'install:path  '; ng ui::data (ng install:path)
    printf 'install:p.loc '; ng ui::data (ng install:path.local)
    printf 'config:       '; ng config:
    ng ui::section META
    printf 'loud          '; ng meta::loud:
    ng ui::section SYSTEMD
    printf 'sctl status   '; ng status
  else if test "$argv[1]" = "help"
    for cmd in \
        clean \
        "config:{,.,path{,.local},list,test}" \
        help \
        "install{:,.,-}" \
        install \
        "log ARGV..." \
        "meta::loud:{,test,.,-}" \
        "relart       -> reload && restart" \
        "relinstall   -> install && reload && restart" \
        reload \
        reload: \
        "sd_comp:{,=}" \
        "sd_unit_{type,scope}:{,=}" \
        "socket:(de)activ(ate)" \
        "srv:{,=}" \
        "s            -> status | cat" \
        "sum::stdin" \
        "(systemctl) [(re)start|stop|status] $ng_service ARGV..." \
        "test:installed" \
        "{un,}install::" \
        "ui::{col,end,process_item,note_su,section,report:{0,1},sem:{srv,installing,shadow},warn,failxplain,data}" \
    ;
      printf '[ - ]   %s\n' "$cmd"
    end
  else
    eval (ng sd_comp:raw)ctl "$argv[1]" (ng srv:raw) $argv[2..]
  end
end
