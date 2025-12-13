# Network Troubleshooting Guide for Flutter/Gradle Builds

## Overview

This guide helps diagnose and resolve network connectivity issues that prevent Gradle from downloading dependencies when building Flutter applications.

## Common Network Issues

### 1. Firewall Blocking
Corporate or personal firewalls may block Gradle's network connections.

**Solutions:**
- Add exceptions for Java/Gradle in your firewall settings
- Temporarily disable firewall to test (not recommended for production)
- Configure firewall to allow connections to gradle.org and related domains

### 2. Proxy Configuration
Corporate networks often require proxy configuration.

**Solutions:**
Add proxy settings to [gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties):
```properties
systemProp.http.proxyHost=your.proxy.host
systemProp.http.proxyPort=8080
systemProp.https.proxyHost=your.proxy.host
systemProp.https.proxyPort=8080
systemProp.http.nonProxyHosts=localhost|127.0.0.1
```

### 3. DNS Resolution Issues
DNS servers may not be able to resolve gradle.org or related domains.

**Solutions:**
- Change DNS servers to Google DNS (8.8.8.8, 8.8.4.4) or Cloudflare DNS (1.1.1.1)
- Flush DNS cache: `ipconfig /flushdns` on Windows
- Test DNS resolution: `nslookup services.gradle.org`

### 4. Network Throttling
Some ISPs or networks throttle connections to certain services.

**Solutions:**
- Try using a VPN service
- Connect to a different network (mobile hotspot, different WiFi)
- Try at a different time of day

## Diagnostic Commands

### Test Basic Connectivity
```cmd
ping gradle.org
ping services.gradle.org
```

### Test HTTPS Connectivity
```cmd
curl -v https://services.gradle.org/distributions/
```

### Test Port Connectivity
```cmd
telnet services.gradle.org 443
```

## Gradle Configuration Solutions

### 1. Increase Timeouts
In [gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties):
```properties
# Increase timeout to 5 minutes
org.gradle.internal.http.connectionTimeout=300000
org.gradle.internal.http.socketTimeout=300000
```

### 2. Enable Retry Mechanism
In [gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties):
```properties
# Enable retry mechanism
org.gradle.internal.repository.max.retries=5
org.gradle.internal.repository.checksums.error-action=warn
```

### 3. Use Different Repositories
In your [build.gradle](file://c:\sumquiz\sumquiz-flutter\android\build.gradle.kts) files, try alternative repositories:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        // Add alternative repositories
        maven { url 'https://repo1.maven.org/maven2' }
        maven { url 'https://jcenter.bintray.com' }
    }
}
```

## Flutter-Specific Solutions

### 1. Use Flutter's Built-in Mirrors
Some regions have better connectivity to specific mirrors:
```cmd
flutter config --no-analytics
flutter pub pub upgrade
```

### 2. Pre-download Dependencies
```cmd
flutter pub get
flutter pub upgrade
```

### 3. Clear Cache and Retry
```cmd
flutter clean
flutter pub cache repair
```

## Advanced Troubleshooting

### 1. Enable Debug Logging
Run Gradle with debug logging:
```cmd
cd android
.\gradlew build --debug
```

### 2. Check Network Configuration
Verify your network settings:
```cmd
ipconfig /all
netstat -an
```

### 3. Monitor Network Traffic
Use tools like Wireshark to monitor network traffic during builds.

## Platform-Specific Solutions

### Windows

1. **Check Windows Defender Firewall:**
   - Open Windows Defender Firewall settings
   - Allow Java/Gradle through firewall
   - Check for blocking rules

2. **Check Windows Proxy Settings:**
   - Open Internet Options
   - Go to Connections > LAN Settings
   - Check if proxy is enabled

3. **Check Windows Update:**
   - Ensure Windows is up to date
   - Some network issues are resolved with Windows updates

### macOS

1. **Check System Proxy Settings:**
   - System Preferences > Network > Advanced > Proxies
   - Check if proxy is configured

2. **Check Firewall:**
   - System Preferences > Security & Privacy > Firewall
   - Ensure firewall isn't blocking connections

### Linux

1. **Check iptables:**
   ```bash
   sudo iptables -L
   ```

2. **Check proxy settings:**
   ```bash
   echo $http_proxy
   echo $https_proxy
   ```

## Corporate Network Solutions

### 1. Certificate Issues
Corporate networks may use custom certificates that Gradle doesn't trust.

**Solutions:**
- Import corporate certificates into Java keystore
- Disable certificate checking (not recommended for security)

### 2. Repository Mirrors
Many organizations provide internal mirrors of public repositories.

**Solutions:**
- Configure Gradle to use internal mirrors
- Check with your IT department for approved repositories

## Testing Network Performance

### 1. Speed Tests
Test your internet connection speed to ensure adequate bandwidth.

### 2. Latency Tests
High latency can cause timeouts:
```cmd
ping -n 10 services.gradle.org
```

### 3. Download Tests
Test download speeds:
```cmd
curl -o /dev/null -s -w "%{time_total}\n" https://services.gradle.org/distributions/gradle-8.12-all.zip
```

## Emergency Solutions

### 1. Offline Mode
If all else fails, work in offline mode:
```cmd
flutter run --offline
```

### 2. Manual Dependency Installation
Download dependencies manually and place them in the appropriate directories.

### 3. Use Alternative Networks
- Mobile hotspot
- Different WiFi network
- VPN service

## Prevention

### 1. Regular Maintenance
- Keep Flutter and dependencies updated
- Regularly clean Gradle cache
- Monitor network connectivity

### 2. Configuration Backup
- Keep backup copies of working [gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties) files
- Document network configuration changes

### 3. Monitoring
- Monitor build times for performance degradation
- Set up alerts for repeated build failures

## Need More Help?

If you continue to experience network issues:

1. Check the Gradle forums: https://discuss.gradle.org/
2. Review the Flutter community: https://flutter.dev/community
3. Consult your network administrator for corporate environments
4. File issues with specific error messages and logs