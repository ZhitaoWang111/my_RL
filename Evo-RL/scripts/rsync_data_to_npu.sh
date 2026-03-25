#!/bin/bash
# =============================================================================
# rsync_data_to_npu.sh — 将本地训练数据集同步到昇腾 NPU 服务器
#
# 同步两个数据集:
#   fold_cloth:          /media/wzt/cfy/pi-finetune/fold_cloth/
#                     -> /home/ma-user/work/wzt/fold_cloth/
#   fold_cloth_Kai0_v3: /media/wzt/cfy/pi-finetune/fold_cloth_Kai0_v3/
#                     -> /home/ma-user/work/wzt/fold_cloth_Kai0_v3/
#
# 用法:
#   bash scripts/rsync_data_to_npu.sh
#
# 支持断点续传: 中断后重新运行即可继续
# 注意: 需要 NPU SSH 密码，脚本不存储任何密码
# =============================================================================

set -euo pipefail

NPU_HOST="ma-user@dev-modelarts.cn-southwest-2.huaweicloud.com"
NPU_PORT=31274

echo ""
echo "============================================="
echo "  rsync: 数据集同步到昇腾 NPU 服务器"
echo "  连接:  SSH 端口 ${NPU_PORT}"
echo "============================================="
echo ""

# Dataset 1: fold_cloth
echo "=== Syncing fold_cloth ==="
rsync -avz --progress \
    /media/wzt/cfy/pi-finetune/fold_cloth/ \
    "${NPU_HOST}:/home/ma-user/work/wzt/fold_cloth/" \
    -e "ssh -p 31274"

echo "fold_cloth sync done."
echo ""

# Dataset 2: fold_cloth_Kai0_v3
echo "=== Syncing fold_cloth_Kai0_v3 ==="
rsync -avz --progress \
    /media/wzt/cfy/pi-finetune/fold_cloth_Kai0_v3/ \
    "${NPU_HOST}:/home/ma-user/work/wzt/fold_cloth_Kai0_v3/" \
    -e "ssh -p 31274"

echo "fold_cloth_Kai0_v3 sync done."
echo ""
echo "All datasets synced to NPU."
