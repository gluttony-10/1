#!/bin/bash
# LoRA train script by @Akegarasu modify by @Gluttony10

# Train data path | 设置训练用模型、图片
pretrained_model="./stable-diffusion-webui/models/Stable-diffusion/chilloutmix-Ni.safetensors" # base model path | 底模路径
is_v2_model=0                             # SD2.0 model | SD2.0模型 2.0模型下 clip_skip 默认无效
v_parameterization=0 # parameterization | 参数化 v2 非512基础分辨率版本必须使用。
train_data_dir="./train"              # train dataset path | 训练数据集路径
reg_data_dir=""                           # directory for regularization images | 正则化数据集路径，默认不使用正则化图像。
training_comment="this_LoRA_model_credit_from_Gluttony10"	# training_comment | 训练介绍，可以写作者名或者使用触发关键词
cache_latents_to_disk=1 #开启缓存潜变量保存到磁盘，这样下次训练不用再次缓存转换，速度更快

# Train related params | 训练相关参数
resolution="512,512"  # image resolution w,h. 图片分辨率，宽,高。支持非正方形，但必须是 64 倍数。
batch_size=3        # batch size
vae_batch_size=3 #vae初始化转换图片批处理大小，2-4。大了可以让一开始处理图片更快
max_train_epoches=10  # max train epoches | 最大训练 epoch
save_every_n_epochs=1 # save every n epochs | 每 N 个 epoch 保存一次

gradient_checkpointing=0 #梯度检查，开启后可节约显存，但是速度变慢
gradient_accumulation_steps=64 # 梯度累加数量，变相放大batchsize的倍数

network_dim=32   # network dim | 常用 4~128，不是越大越好
network_alpha=32 # network alpha | 常用与 network_dim 相同的值或者采用较小的值，如 network_dim的一半 防止下溢。默认值为 1，使用较小的 alpha 需要提升学习率。

train_unet_only=0         # train U-Net only | 仅训练 U-Net，开启这个会牺牲效果大幅减少显存使用。6G显存可以开启
train_text_encoder_only=0 # train Text Encoder only | 仅训练 文本编码器

seed="1026" # reproducable seed | 设置跑测试用的种子，输入一个prompt和这个种子大概率得到训练图。可以用来试触发关键词

noise_offset=0 # noise offset | 在训练中添加噪声偏移来改良生成非常暗或者非常亮的图像，如果启用，推荐参数为0.1
multires_noise_iterations=6 #多分辨率噪声扩散次数，推荐6-10,0禁用,和noise_offset冲突，只能开一个
multires_noise_discount=0.4 #多分辨率噪声缩放倍数，推荐0.1-0.3,上面关掉的话禁用。

shuffle_caption=1 # 随机打乱tokens顺序，默认启用。修改为 0 禁用。
keep_tokens=3  # keep heading N tokens when shuffling caption tokens | 在随机打乱 tokens 时，保留前 N 个不变。
no_token_padding=0 #不进行分词器填充

prior_loss_weight=1 #正则化权重，0-1

# Learning rate | 学习率
lr="2e-4"
unet_lr="2e-4"
text_encoder_lr="2e-5"
lr_scheduler="cosine_with_restarts" # "linear", "cosine", "cosine_with_restarts", "polynomial", "constant", "constant_with_warmup"
lr_warmup_steps=0                   # warmup steps | 仅在 lr_scheduler 为 constant_with_warmup 时需要填写这个值
lr_restart_cycles=1                 # cosine_with_restarts restart cycles | 余弦退火重启次数，仅在 lr_scheduler 为 cosine_with_restarts 时起效。
min_snr_gamma=5 #最小信噪比伽马值，减少低step时loss值，让学习效果更好。推荐3-5，5对原模型几乎没有太多影响，3会改变最终结果。修改为0禁用。
weighted_captions=0 #权重打标，默认识别标签权重，语法同webui基础用法。例如(abc), [abc], (abc:1.23),但是不能再括号内加逗号，否则无法识别。

# block weights | 分层训练
enable_block_weights=0 #开启分层训练
down_lr_weight="1,0.2,1,1,0.2,1,1,0.2,1,1,1,1" #12层，需要填写12个数字，0-1.也可以使用函数写法，支持sine, cosine, linear, reverse_linear, zeros，参考写法down_lr_weight=cosine+.25 
mid_lr_weight="1"  #1层，需要填写1个数字，其他同上。
up_lr_weight="1,1,1,1,1,1,1,1,1,1,1,1"   #12层，同上上。
block_lr_zero_threshold=0  #如果分层权重不超过这个值，那么直接不训练。默认0。

enable_enable_block_dim=0 #开启分块dim训练
block_dims="128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128" #dim分块，25块
block_alphas="16,16,32,16,32,32,64,16,16,64,64,64,16,64,16,64,32,16,16,64,16,16,16,64,16"  #alpha分块，25块
conv_block_dims="32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32" #convdim分块，25块
conv_block_alphas="1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1" #convalpha分块，25块

# Output settings | 输出设置
output_name="glut"           # output model name | 模型保存名称
save_model_as="safetensors" # model save ext | 模型保存格式 ckpt, pt, safetensors
mixed_precision="fp16" # bf16效果更好但是30系以下显卡不支持，默认fp16
save_precision="fp16" # bf16效果更好但是30系以下显卡不支持，默认fp16

# wandb 
wandb_api_key="f48f5636074fa8150f857a1535cf942a66d1b8ee"
log_tracker_name=$output_name

# Sample output | 出图
enable_sample=1 #开启出图
sample_every_n_epochs=1 #每n个epoch出一次图
sample_prompts="./sample_prompts.txt" #prompt文件路径
sample_sampler="dpmsolver++" #采样器 'ddim', 'pndm', 'heun', 'dpmsolver', 'dpmsolver++', 'dpmsingle', 'k_lms', 'k_euler', 'k_euler_a', 'k_dpm_2', 'k_dpm_2_a'

# 其他设置
network_weights=""               # pretrained weights for LoRA network | 若需要从已有的 LoRA 模型上继续训练，请填写 LoRA 模型路径。
min_bucket_reso=256              # arb min resolution | arb 最小分辨率
max_bucket_reso=1024             # arb max resolution | arb 最大分辨率
persistent_data_loader_workers=1 # persistent dataloader workers | 容易爆内存，保留加载训练集的worker，减少每个 epoch 之间的停顿
clip_skip=2                      # clip skip | 玄学 一般用 2

# 优化器设置
optimizer_type="Lion" 
# 可选优化器"adaFactor","AdamW","AdamW8bit","Lion","SGDNesterov","SGDNesterov8bit","DAdaptation"(DAdaptAdam),  
# 新增优化器"Lion8bit"(速度更快，内存消耗更少)、"DAdaptAdaGrad"、"DAdaptAdan"(北大最新算法，效果待测)、"DAdaptSGD"

# lycoris 训练设置
enable_lycoris_train=0 # enable lycoris train | 启用 LoCon 训练 启用后 network_dim 和 network_alpha 应当选择较小的值，比如 2~16
conv_dim=0           # conv dim | 类似于 network_dim，推荐为 4
conv_alpha=0         # conv alpha | 类似于 network_alpha，可以采用与 conv_dim 一致或者更小的值
algo="dylora" # algo参数，制定训练lycoris模型种类，包括lora(locon)、loha、IA3以及lokr、dylora 。5个可选

# dylora 训练设置
enable_dylora_train=0 # enable dylora train | 启用 LoCon 训练 启用后 network_dim 和 network_alpha 应当选择较小的值，比如 2~16
unit=4	#block size

# ============= DO NOT MODIFY CONTENTS BELOW | 请勿修改下方内容 =====================
export HF_HOME="huggingface"
export TF_CPP_MIN_LOG_LEVEL=3

network_module="networks.lora"
extArgs=()

if [ $train_unet_only == 1 ]; then extArgs+=("--network_train_unet_only"); fi

if [ $train_text_encoder_only == 1 ]; then extArgs+=("--network_train_text_encoder_only"); fi

if [ $network_weights ]; then extArgs+=("--network_weights=$network_weights"); fi

if [ $reg_data_dir ]; then extArgs+=("--reg_data_dir=$reg_data_dir"); fi

if [ $shuffle_caption == 1 ]; then extArgs+=("--shuffle_caption"); fi

if [ $persistent_data_loader_workers == 1 ]; then extArgs+=("--persistent_data_loader_workers"); fi

if [ $weighted_captions == 1 ]; then extArgs+=("--weighted_captions"); fi

if [ $cache_latents_to_disk == 1 ]; then extArgs+=("--cache_latents_to_disk"); fi

if [[ $no_token_padding -ne 0 ]]; then extArgs+=("--no_token_padding"); fi

if [ $enable_lycoris_train == 1 ]; then
  network_module="lycoris.kohya"
  extArgs+=("--network_args conv_dim=$conv_dim conv_alpha=$conv_alpha algo=$algo")

elif [ $enable_dylora_train == 1 ]; then
  network_module="networks.dylora"
  extArgs+=("--network_args unit=$unit")

elif [ $enable_block_weights == 1 ]; then
  extArgs+=("--network_args down_lr_weight=$down_lr_weight mid_lr_weight=$mid_lr_weight up_lr_weight=$up_lr_weight block_lr_zero_threshold=$block_lr_zero_threshold")
  if [ $enable_enable_block_dim == 1 ]; then
    extArgs+=("block_dims=$block_dims block_alphas=$block_alphas")
    if [ $conv_block_dims ]; then
      extArgs+=("conv_block_dims=$conv_block_dims conv_block_alphas=$conv_block_alphas")
    fi
  fi
fi

if [[ $optimizer_type == "AdamW8bit" ]]; then
  optimizer_type=""
  extArgs+=("--use_8bit_adam")

elif [[ $optimizer_type == "Lion" ]] || [[ $optimizer_type == "Lion8bit" ]]; then
  extArgs+=("--optimizer_type=$optimizer_type" "--optimizer_args weight_decay=0.01 betas=.95,.98")

elif [[ $optimizer_type == "DAdaptation" ]] || [[ $optimizer_type == "DAdaptAdam" ]] ; then
  extArgs+=("--optimizer_type=$optimizer_type" "--optimizer_args weight_decay=0.01 decouple=True")
  lr="1"
  unet_lr="1"
  text_encoder_lr="1"

elif [[ $optimizer_type == "DAdaptAdan" ]] || [[ $optimizer_type == "DAdaptSGD" ]] || [[ $optimizer_type == "DAdaptAdaGrad" ]]; then
  extArgs+=("--optimizer_type=$optimizer_type")
  lr="1"
  unet_lr="1"
  text_encoder_lr="1"
  
elif [[ $optimizer_type == "adafactor" ]]; then
  extArgs+=("--optimizer_type=$optimizer_type" "--optimizer_args scale_parameter=True warmup_init=True")
fi

if [[ $noise_offset -ne 0 ]]; then 
  extArgs+=("--noise_offset=$noise_offset"); 
elif [[ $multires_noise_iterations -ne 0 ]]; then 
  extArgs+=("--multires_noise_iterations=$multires_noise_iterations"); 
  extArgs+=("--multires_noise_discount=$multires_noise_discount"); 
fi

if [[ $vae_batch_size -ne 0 ]]; then extArgs+=("--vae_batch_size=$vae_batch_size"); fi

if [[ $min_snr_gamma -ne 0 ]]; then extArgs+=("--min_snr_gamma=$min_snr_gamma"); fi

if [[ $gradient_checkpointing -ne 0 ]]; then extArgs+=("--gradient_checkpointing"); fi

if [[ $gradient_accumulation_steps -ne 0 ]]; then extArgs+=("--gradient_accumulation_steps=$gradient_accumulation_steps"); fi

if [[ $is_v2_model == 1 ]]; then
  extArgs+=("--v2");
  extArgs+=("--v_parameterization");
else
  extArgs+=("--clip_skip=$clip_skip");
fi

if [ $wandb_api_key ]; then
  extArgs+=("--wandb_api_key=$wandb_api_key");
  extArgs+=("--log_with=wandb");
  extArgs+=("--log_tracker_name=$log_tracker_name");
fi

if [ $enable_sample == 1 ]; then
  extArgs+=("--sample_every_n_epochs=$sample_every_n_epochs");
  extArgs+=("--sample_prompts=$sample_prompts");
  extArgs+=("--sample_sampler=$sample_sampler");
fi

accelerate launch --num_cpu_threads_per_process=8 "./sd-scripts/train_network.py" \
  --enable_bucket \
  --pretrained_model_name_or_path=$pretrained_model \
  --train_data_dir=$train_data_dir \
  --output_dir="./output" \
  --logging_dir="./logs" \
  --resolution=$resolution \
  --network_module=$network_module \
  --max_train_epochs=$max_train_epoches \
  --learning_rate=$lr \
  --unet_lr=$unet_lr \
  --text_encoder_lr=$text_encoder_lr \
  --lr_scheduler=$lr_scheduler \
  --lr_warmup_steps=$lr_warmup_steps \
  --lr_scheduler_num_cycles=$lr_restart_cycles \
  --network_dim=$network_dim \
  --network_alpha=$network_alpha \
  --output_name=$output_name \
  --train_batch_size=$batch_size \
  --save_every_n_epochs=$save_every_n_epochs \
  --mixed_precision=$mixed_precision \
  --save_precision=$save_precision \
  --seed=$seed \
  --cache_latents \
  --prior_loss_weight=$prior_loss_weight \
  --max_token_length=225 \
  --caption_extension=".txt" \
  --save_model_as=$save_model_as \
  --min_bucket_reso=$min_bucket_reso \
  --max_bucket_reso=$max_bucket_reso \
  --keep_tokens=$keep_tokens \
  --training_comment=$training_comment \
  --xformers \
  ${extArgs[@]}
