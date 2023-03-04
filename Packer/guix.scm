;; echo PACKER_CACHE_DIR=/srv/packer/cache PACKER_LOG=1 packer build -var virtio_win_iso=/srv/lib/virtio-win.iso -only=qemu -var iso_url=/srv/packer/cache/fbe860439e10a6d50766c5ec20ebd394160a1b61.iso windows_10.json

(use-modules (gnu packages guile)
             (guix gexp)
             (guix modules)
             (guix utils)
             (ice-9 match)
             (ice-9 ftw)
             (srfi srfi-1)
             (srfi srfi-26))

;; TODO: Use Packer from Guix package collection
(define %packer
  (and=> (getenv "HOME")
         (lambda (home)
           (string-append home "/.nix-profile/bin/packer"))))

(define %packer-operating-system
  #~(("variables"
      ("packer_build_dir" . "./win10")
      ("autounattend_virtio"
       .
       #$(local-file "answer_files/10_virtio/Autounattend.xml"))
      ("virtio_win_iso" . "./virtio-win.iso")
      ("disk_size" . "32768")
      ("autounattend"
       .
       #$(local-file "answer_files/10/Autounattend.xml"))
      ("iso_url"
       .
       "https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso")
      ("iso_checksum"
       .
       "sha256:9ef81b6a101afd57b2dbfa44d5c8f7bc94ff45b51b82c5a1f9267ce2e63e9f53"))
     ("provisioners"
      .
      #((("scripts" . #("./scripts/enable-rdp.bat"))
         ("execute_command"
          .
          "{{ .Vars }} cmd /c \"{{ .Path }}\"")
         ("remote_path" . "/tmp/script.bat")
         ("type" . "windows-shell"))
        (("scripts"
          .
          #("./scripts/vm-guest-tools.ps1"
            "./scripts/debloat-windows.ps1"))
         ("type" . "powershell"))
        (("type" . "windows-restart"))
        (("scripts"
          .
          #("./scripts/set-powerplan.ps1"
            "./scripts/docker/disable-windows-defender.ps1"
            "./scripts/looking-glass.ps1"
            "./scripts/virtio.ps1"))
         ("type" . "powershell"))
        (("scripts"
          .
          #("./scripts/pin-powershell.bat"
            "./scripts/compile-dotnet-assemblies.bat"
            "./scripts/set-winrm-automatic.bat"
            "./scripts/dis-updates.bat"))
         ("execute_command"
          .
          "{{ .Vars }} cmd /c \"{{ .Path }}\"")
         ("remote_path" . "/tmp/script.bat")
         ("type" . "windows-shell"))))
     ("builders"
      .
      #((("floppy_files"
          .
          #("{{user `autounattend_virtio`}}"
            "./floppy/WindowsPowershell.lnk"
            "./floppy/PinTo10.exe"
            "./scripts/fixnetwork.ps1"
            "./scripts/rearm-windows.ps1"
            "./scripts/disable-screensaver.ps1"
            "./scripts/disable-winrm.ps1"
            "./scripts/enable-winrm.ps1"
            "./scripts/microsoft-updates.bat"
            "./scripts/win-updates.ps1"
            "./scripts/unattend.xml"
            "./scripts/sysprep.bat"))
         ("qemuargs"
          .
          #(#("-m" "2048")
            #("-smp" "2")
            #("-drive"
              "file={{ user `virtio_win_iso` }},media=cdrom,index=3")
            #("-drive"
              "file={{ user `packer_build_dir`}}/{{ .Name }},if=virtio,cache=writeback,discard=ignore,format=qcow2,index=1")
            #("-drive"
              "file={{ user `iso_url` }},media=cdrom,index=2")
            #("-bios"
              "/nix/store/jk2yj6fvl38as63afxxd1wsjz03xd07h-OVMF-202102-fd/FV/OVMF.fd")))
         ("firmware"
          .
          "/nix/store/jk2yj6fvl38as63afxxd1wsjz03xd07h-OVMF-202102-fd/FV/OVMF_CODE.fd")
         ("output_directory"
          .
          "{{ user `packer_build_dir`}}")
         ("disk_size" . "{{user `disk_size`}}")
         ("accelerator" . "kvm")
         ("shutdown_command" . "a:/sysprep.bat")
         ("shutdown_timeout" . "2h")
         ("winrm_timeout" . "4h")
         ("winrm_password" . "vagrant")
         ("winrm_username" . "vagrant")
         ("boot_command" . "")
         ("boot_wait" . "6m")
         ("headless" . #f)
         ("iso_checksum" . "{{user `iso_checksum`}}")
         ("iso_url" . "{{user `iso_url`}}")
         ("communicator" . "winrm")
         ("vm_name" . "windows_10")
         ("type" . "qemu"))))))

(define windows_10.json
  (mixed-text-file "windows_10.json"
                   (with-extensions (list guile-json-4)
                     (with-imported-modules (source-module-closure '((json builder)))
                       #~(begin
                           (use-modules (json builder))
                           (scm->json-string '#$%packer-operating-system))))))

windows_10.json
