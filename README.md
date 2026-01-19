# Claude Sync System

## For Phone Claude (in Debian):
Read Windows messages:
```bash
cat /sdcard/claude-sync/from-windows.md
```

Write reports for Windows:
```bash
cat > /sdcard/claude-sync/from-phone.md << 'EOF'
# Your report here
EOF
```

## For Windows Claude:
Push to phone:
```bash
adb push file.md /sdcard/claude-sync/
```

Pull from phone:
```bash
adb pull /sdcard/claude-sync/from-phone.md
```

## Sync folder location:
- Phone: `/sdcard/claude-sync/`
- Windows: `C:\Users\pkoaw\AndroidStudioProjects\claude-sync\`
