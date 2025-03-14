DATA_ROOT="/mnt/yrfs/litianjian/mGLM/multi-finetune/xtreme-master/download"
CHECKPOINT_PATH="new_checkpoints"
SAVE_PATH="finetune_checkpoints"
DATESTR=$(date +"%m-%d-%H-%M")

source $1    # Model
source $2    # Task

MP_SIZE=1
MASTER_PORT=$(shuf -n 1 -i 10000-65535)

if [ -z $AVAILABLE_DEVICES ];then
  AVAILABLE_DEVICES=0,1,2,3,4,5,6,7
fi
OPTIONS_NCCL="NCCL_DEBUG=info NCCL_IB_DISABLE=0 NCCL_NET_GDR_LEVEL=2"
DISTRIBUTED_ARGS="${OPTIONS_NCCL} deepspeed --master_port $MASTER_PORT --include localhost:${AVAILABLE_DEVICES}"

mkdir logs/${TASK_NAME}
EXPERIMENT_NAME=${EXPERIMENT_NAME}_${DATESTR}
run_cmd="${DISTRIBUTED_ARGS} finetune_glm.py \
       --deepspeed \
       --deepspeed_config config_tasks/config_blocklm_large.json \
       --finetune \
       --cloze-eval \
       --experiment-name ${EXPERIMENT_NAME} \
       --task ${TASK_NAME} \
       --data-dir ${DATA_PATH} \
       --save ${SAVE_PATH} \
       --seq-length ${MAX_SEQ_LEN} \
       --checkpoint-activations \
       --eval-batch-size 16 \
       --save-epoch 100000 \
       --num-workers 1 \
       --no-load-optim \
       --no-load-lr-scheduler \
       $MODEL_ARGS \
       $TRAIN_ARGS \
       $COMMON_ARGS \
       --fp16 \
       --model-parallel-size ${MP_SIZE} \
       --epochs ${XXLARGE_EPOCH} \
       --overwrite \
       2>&1 | tee logs/${TASK_NAME}/log-${EXPERIMENT_NAME}.txt"

echo ${run_cmd}
eval ${run_cmd}
