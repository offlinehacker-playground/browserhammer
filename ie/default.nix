{ stdenv, fetchurl, unrar, unzip, qemu, libguestfs
, selenium-server-standalone }:

stdenv.mkDerivation {
  name = "ie8";

  image = stdenv.mkDerivation {
    name = "ie8-vmdk";
    src = [
      (fetchurl {
        url = https://az412801.vo.msecnd.net/vhd/VMBuild_20131127/VirtualBox/IE8_Win7/Linux/IE8.Win7.For.LinuxVirtualBox.part1.sfx;
        md5 = "30ad44d37e54c9bc75b7c5b68577b124";
      })
      (fetchurl {
        url = https://az412801.vo.msecnd.net/vhd/VMBuild_20131127/VirtualBox/IE8_Win7/Linux/IE8.Win7.For.LinuxVirtualBox.part2.rar;
        md5 = "b30ad62ec4c6084f64796ec1bd0abd44";
      })
      (fetchurl {
        url = https://az412801.vo.msecnd.net/vhd/VMBuild_20131127/VirtualBox/IE8_Win7/Linux/IE8.Win7.For.LinuxVirtualBox.part3.rar;
        md5 = "d05a32f3157ac6ff59e06980fb1b1a0d";
      })
      (fetchurl {
        url = https://az412801.vo.msecnd.net/vhd/VMBuild_20131127/VirtualBox/IE8_Win7/Linux/IE8.Win7.For.LinuxVirtualBox.part4.rar;
        md5 = "b5a834e230ba500154923caccba8ec03";
      })
    ];

    buildInputs = [ unrar ];
    buildCommand = ''
      for part in $src; do ln -s "$part" $(echo "$(basename $part)" | cut -c34-); done 
      unrar x $(basename $(echo "$src" | cut -f 1 -d " ") | cut -c34-)
      mv *.ova ie.tar
      tar -xf ie.tar && rm ie.tar
      mv *.vmdk $out
    '';
  };

  openjdk = stdenv.mkDerivation {
    name = "openjdk-i686-windows";

    src = fetchurl {
      url = "https://bitbucket.org/alexkasko/openjdk-unofficial-builds/downloads/openjdk-1.7.0-u60-unofficial-windows-i586-image.zip";
      sha256 = "70691d01a3448d718a9319107fc9ab04cd86020869827573f93df89289258289";
    };
    phases = ["unpackPhase" "installPhase"];

    buildInputs = [ unzip ];
    
    installPhase = "mkdir -p $out && mv * $out";
  };

  iedriver = stdenv.mkDerivation {
    name = "iedriver";
    src = fetchurl {
      url = "http://selenium-release.storage.googleapis.com/2.44/IEDriverServer_Win32_2.44.0.zip";
      sha256 = "1hjfbd0wi7xz81rh5zfwnfsx9m1ri5h9rxgwkzjvsd86kbz2r1jp";
    };
    sourceRoot = "./";
    
    buildInputs = [ unzip ];
    
    installPhase = ''
      mkdir -p $out/bin
      mv IEDriverServer.exe $out/bin/IEDriverServer.exe
    '';
  };

  buildInputs = [ unrar unzip libguestfs qemu ];

  buildCommand = ''
    qemu-img create -o backing_file="$image" -f qcow2 $out

    echo "Quering parameters from win registry"
    CURRENT_CONTROL_SET=$(printf "%03d" "$(virt-win-reg $out 'HKLM\SYSTEM\Select' Current)")
    SID=$(virt-win-reg $out 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | grep -E -o 'S-[0-9]-[0-9]+-([0-9]+-){1,14}[0-9]+' | head -n 1)

    echo "Control set: $CURRENT_CONTROL_SET, SID: \"$SID\""

    cat > fwdisable.reg <<EOF
    [HKLM\SYSTEM\ControlSet$CURRENT_CONTROL_SET\services\SharedAccess\Parameters\FirewallPolicy\StandardProfile]
    "DisableNotifications"=dword:00000000
    "EnableFirewall"=dword:00000000

    [HKLM\SYSTEM\ControlSet$CURRENT_CONTROL_SET\services\SharedAccess\Parameters\FirewallPolicy\PublicProfile]
    "DisableNotifications"=dword:00000000
    "EnableFirewall"=dword:00000000

    [HKLM\SYSTEM\ControlSet$CURRENT_CONTROL_SET\Control\Network\NetworkLocationWizard]
    "HideWizard"=dword:00000001

    [HKEY_USERS\\$SID\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3]
    "2500"=dword:00000003

    [HKEY_USERS\\$SID\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4]
    "2500"=dword:00000003
    EOF

    cat > _selenium.bat <<'EOF'
    timeout /t 15
    c:\\selenium\\openjdk\\bin\\java.exe -jar c:\\selenium\\selenium-server-standalone.jar -role webdriver -hub http://10.0.2.2:4444/ -host 127.0.0.1 -Dwebdriver.ie.driver=C:\\selenium\\IEDriverServer.exe
    EOF
    sed 's/''$'"/`echo \\\r`/" _selenium.bat > selenium.bat

    cat > boot.reg <<'EOF'
    [HKLM\Software\Microsoft\Windows\CurrentVersion\Run]
    "Selenium"="c:\\selenium\\selenium.bat"
    EOF

    echo "Uploading files to VM"
    guestfish -i -a $out <<EOF
       mkdir /selenium
       copy-in $openjdk/ /selenium/
       glob mv /selenium/* /selenium/openjdk
       upload $iedriver/bin/IEDriverServer.exe /selenium/IEDriverServer.exe
       upload ${selenium-server-standalone}/share/lib/${selenium-server-standalone.name}/${selenium-server-standalone.name}.jar /selenium/selenium-server-standalone.jar 
       upload selenium.bat /selenium/selenium.bat
    EOF

    echo "Disabling security features"
    virt-win-reg --merge $out fwdisable.reg

    echo "Configuring selenium to start at boot"
    virt-win-reg --merge $out boot.reg 
  '';
}
