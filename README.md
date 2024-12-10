# File Encryption and Transfer Automation Scripts

This repository contains bash scripts to automate file encryption using GPG, secure file transfer via `lftp`, and directory monitoring for new files. The scripts ensure secure handling and organized processing of sensitive data.

---

## Table of Contents
- [Features](#features)
- [File Structure](#file-structure)
- [Prerequisites](#prerequisites)
- [Scripts Overview](#scripts-overview)
  - [File Encryption and Transfer Script](#file-encryption-and-transfer-script)
  - [Directory Monitoring Script](#directory-monitoring-script)
- [Logs](#logs)
- [Usage](#usage)
- [License](#license)

---

## Features

1. **File Encryption**:  
   Encrypts files in the specified directory using GPG and a public key.

2. **File Transfer**:  
   Transfers encrypted files and public keys securely using SFTP (`lftp`).

3. **Directory Monitoring**:  
   Watches a directory for new files and processes them automatically.

4. **Error Handling**:  
   Logs all actions and handles failed operations by moving files to a `failed` directory.

5. **File Organization**:  
   Archives successfully transferred files for record-keeping.

---

## File Structure

| **Folder**          | **Description**                          |
|----------------------|------------------------------------------|
| `$INIT`         | Directory for incoming files to be encrypted. |
| `$ENCRYPTED`    | Directory for encrypted files ready for transfer. |
| `$ARCHIVED`     | Directory for successfully transferred files. |
| `$FAILED`       | Directory for failed files. |
| `$KEY`             | Path to the GPG public key file. |
| `$PWD`             | Path to the SFTP password file. |

---

## Prerequisites

### Required Tools
Ensure the following tools are installed:
- `GPG`: For file encryption.
- `lftp`: For secure file transfer.
- `inotify-tools`: For directory monitoring.

Install using the following commands:
```bash
# On Debian/Ubuntu
sudo apt-get install gpg lftp inotify-tools

# On SUSE
sudo zypper install gpg2 lftp inotify-tools
```

### GPG Key Setup Manually
`gpg --import $KEY`

### Folder Setup
`mkdir -p $INIT $ARCHIVED $ENCRYPTED $FAILED`

### Password File Configuration
Store the SFTP password in the directory `$PWD`

## Scripts Overview

### File Encryption and Transfer Script
**Path**: `encrypt_move_transfer.sh`

This script automates the following tasks:
1. **File Encryption**: Encrypts files located in the `$INIT` directory using the specified GPG public key.
2. **File Organization**: Moves encrypted files to the `$ENCRYPTED` directory.
3. **Secure File Transfer**: Transfers encrypted files and the GPG public key to a remote SFTP server using `lftp`.
4. **Archiving**: Moves successfully transferred files to the `$ARCHIVED` directory.
5. **Error Handling**: Logs failed encryption or transfer attempts and move such files to the `$FAAILED` directory.

#### Usage
Run the script manually:
```bash
bash encrypt_move_transfer.sh
```

### Directory Monitoring
**Path**: `trigger_monitor_directory.sh` & `trigger_monitori_v2.sh`

This script monitors the `$INIT` directory for new files and automatically triggers the encryption and transfer process. It ensures real-time processing of incoming files.

**Features**:
1. **Detects newly created or moved files in the directory.
2. **Logs all detected files and their processing status.
3. **Automatically calls the encrypt_move_transfer.sh script for encryption and transfer.

#### Usage
Run the script manually:
```bash
bash trigger_monitor_directory.sh | trigger_monitori_v2.sh
```

## Logs
### All script operations, including encryption, file transfers, and errors, are logged in:
`monitor_directory_test.log`

### The log file contains:
1. **Timestamped Events: Details of when files were detected, encrypted, transferred, or failed.
2. **Encryption Status: Success or failure of file encryption.
3. **Transfer Status: Whether files and public keys were successfully transferred to the SFTP server.
4. **Error Handling: Information about files moved to the failed directory due to errors.

### Example log entries
```bash
[2024-12-10 14:32:15]: New file detected: $INIT/sample.txt
[2024-12-10 14:32:17]: Encrypted: $INIT/sample.txt
[2024-12-10 14:32:19]: Transferred: $ENCRYPTED/sample.txt.gpg
[2024-12-10 14:32:21]: SUCCESS: File processed and archived successfully.
```


