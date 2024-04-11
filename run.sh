# Copyright 2023 DeepMind Technologies Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# !/bin/bash
set -e
set -x


## New: Install pyenv 
## Following steps at https://www.dedicatedcore.com/blog/install-pyenv-ubuntu/
if ! test -f pyenv_test_switch.txt; then 
	curl https://pyenv.run | bash
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
	echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bashrc
	#exec "$SHELL"
	$HOME/.pyenv/bin/pyenv install 3.10.9
	$HOME/.pyenv/bin/pyenv global 3.10.9
	touch pyenv_test_switch.txt
fi


virtualenv -p python3 .
source ./bin/activate

#pip install --require-hashes -r requirements.txt
pip install -r requirements.in

#gdown --folder https://bit.ly/alphageometry
links  https://drive.google.com/uc?id=1qXkmmgoJ8oTYJdFV1xw0xGPpQj6SyOYA
DATA=ag_ckpt_vocab

MELIAD_PATH=meliad_lib/meliad
rm -rf $MELIAD_PATH
mkdir -p $MELIAD_PATH
git clone https://github.com/google-research/meliad $MELIAD_PATH
export PYTHONPATH=$PYTHONPATH:$MELIAD_PATH

DDAR_ARGS=(
  --defs_file=$(pwd)/defs.txt \
  --rules_file=$(pwd)/rules.txt \
);

BATCH_SIZE=2
BEAM_SIZE=2
DEPTH=2

SEARCH_ARGS=(
  --beam_size=$BEAM_SIZE
  --search_depth=$DEPTH
)

LM_ARGS=(
  --ckpt_path=$DATA \
  --vocab_path=$DATA/geometry.757.model \
  --gin_search_paths=$MELIAD_PATH/transformer/configs \
  --gin_file=base_htrans.gin \
  --gin_file=size/medium_150M.gin \
  --gin_file=options/positions_t5.gin \
  --gin_file=options/lr_cosine_decay.gin \
  --gin_file=options/seq_1024_nocache.gin \
  --gin_file=geometry_150M_generate.gin \
  --gin_param=DecoderOnlyLanguageModelGenerate.output_token_losses=True \
  --gin_param=TransformerTaskConfig.batch_size=$BATCH_SIZE \
  --gin_param=TransformerTaskConfig.sequence_length=128 \
  --gin_param=Trainer.restore_state_variables=False
);

echo $PYTHONPATH

python -m alphageometry \
--alsologtostderr \
--problems_file=$(pwd)/examples.txt \
--problem_name=orthocenter \
--mode=alphageometry \
"${DDAR_ARGS[@]}" \
"${SEARCH_ARGS[@]}" \
"${LM_ARGS[@]}"
