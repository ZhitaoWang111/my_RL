#!/bin/bash
# =============================================================================
# rsync_to_npu.sh — 将本地 Evo-RL 代码同步到昇腾 NPU 服务器
#
# 用法:
#   bash scripts/rsync_to_npu.sh
#
# 同步内容:
#   本地 Evo-RL/ → NPU:/home/ma-user/work/wzt/Evo-RL/
#   排除: .git/ outputs/ pretrained/
#
# 注意:
#   - 需要提供 NPU SSH 密码，脚本不存储任何密码
#   - 连接: ssh -p 31274 ma-user@dev-modelarts.cn-southwest-2.huaweicloud.com
#   - 支持断点续传: 中断后重新运行即可继续
# =============================================================================

set -euo pipefail

# 从脚本位置向上推导 Evo-RL 根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_CODE_DIR="${SCRIPT_DIR}/.."   # Evo-RL/

NPU_HOST="ma-user@dev-modelarts.cn-southwest-2.huaweicloud.com"
NPU_PORT=31274
NPU_CODE_DIR="/home/ma-user/work/wzt/Evo-RL"

echo ""
echo "============================================="
echo "  rsync: 代码同步到昇腾 NPU 服务器"
echo "  本地:  ${LOCAL_CODE_DIR}"
echo "  远端:  ${NPU_HOST}:${NPU_CODE_DIR}/"
echo "  排除:  .git/ outputs/ pretrained/"
echo "  连接:  SSH 端口 ${NPU_PORT}"
echo "============================================="
echo ""

rsync -avz --progress \
    --exclude='.git' \
    --exclude='outputs/' \
    --exclude='pretrained/' \
    "${LOCAL_CODE_DIR}/" \
    "${NPU_HOST}:${NPU_CODE_DIR}/" \
    -e "ssh -p 31274"

echo ""
echo "代码同步完成."
echo "后续步骤: 在 NPU 服务器上进入 ${NPU_CODE_DIR} 运行训练脚本"
