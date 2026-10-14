# Hanabira OS — Live Preview

Hanabira OS เป็นโปรเจกต์เดสก์ท็อปของตัวเองบน Debian 13 และ KDE Plasma
ไฟล์ ISO ปัจจุบันเป็นระบบ **Live** สำหรับลองบูตจาก VM หรือ USB ยังไม่มีตัวติดตั้ง
การเข้า Live session ตามปกติจะไม่เขียนทับระบบที่ติดตั้งอยู่

ต้นแบบเดิมชื่อ Sakura Live ผ่านการทดสอบบูตใน QEMU ทั้ง BIOS และ UEFI
และเข้า Plasma desktop อัตโนมัติที่ 1280×800 แล้ว ส่วน ISO ชื่อ Hanabira
ต้องสร้างใหม่และทดสอบอีกครั้งหลังการเปลี่ยนแบรนด์และธีม

โปรเจกต์นี้ตั้งใจทำภาพรวมระบบให้เข้าชุด ทั้งโหมดสว่าง/มืด วอลล์เปเปอร์
ไอคอน แถบโปรแกรมและหน้าต่าง พร้อมปรับให้ตอบสนองดีบนหลายจอ
แต่ **ยังไม่มีผลทดสอบรับรองความลื่น 240 Hz หรือ RTX 5080**
ISO ไม่ได้รวมไดรเวอร์ NVIDIA แบบ proprietary และยังไม่ได้ทดสอบ Wi-Fi,
เสียง, การปิดเครื่อง, scaling หลายจอ หรือฮาร์ดแวร์จริง

## ลองสร้างและตรวจไฟล์

วิธีสร้างจากสูตรอยู่ใน [README.md](README.md) ตัวเลือกที่สะดวกบน Linux
ที่มี rootless Podman คือ `./scripts/build-container.sh` แล้วตรวจด้วย
`./scripts/verify-iso.sh` ผลลัพธ์จะมี `hanabira-live-amd64.hybrid.iso`,
`SHA256SUMS`, `BUILDINFO.txt`, รายการแพ็กเกจ และสูตรสร้างแบบ `.tar.gz`

ก่อนปล่อย ISO สาธารณะ ให้สร้างพร้อม source image ด้วย
`HANABIRA_BUILD_SOURCES=true ./scripts/build-container.sh` และทำขั้นตอนใน
[docs/RELEASE.md](docs/RELEASE.md) สูตรสร้างของโปรเจกต์เพียงอย่างเดียว
ไม่ใช่ source code ของแพ็กเกจ Debian ทั้งหมดใน ISO

โค้ดของโปรเจกต์ใช้ MIT; ภาพที่สร้างสำหรับโปรเจกต์และภาพบูตใช้ CC BY 4.0
รายละเอียดอยู่ใน [ASSETS.md](ASSETS.md) แพ็กเกจ Debian/KDE ยังคงใช้ไลเซนส์
ของเจ้าของเดิม Hanabira OS ไม่ใช่โปรเจกต์อย่างเป็นทางการของ Debian หรือ KDE
