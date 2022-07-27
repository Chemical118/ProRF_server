# 연구노트
## 7/21
- julia 설치
```
wget https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.3-linux-x86_64.tar.gz
tar zxvf julia-1.7.3-linux-x86_64.tar.gz
```
Python 종속성은 julia 내에서 miniconda 설치해서 해결
- julia 환경 변수 추가

.bashrc 파일 마지막줄에 추가
```
export PATH="$PATH:/home/wowo/julia-1.7.3/bin/"
```

폴더로 이동
```
cd ProRF_server
```

- julia 모듈 설치
  
내가 커스텀 한 모듈을 먼저 설치해야함
```julia
using Pkg
Pkg.add(url="https://github.com/Chemical118/AverageShiftedHistograms.jl")
Pkg.add(url="https://github.com/Chemical118/ProRF.jl")
Pkg.add("JLD2")
```

- 기본적인 workflow 구성
    + `make_seed.jl` : seed 생성 후에 `Save/seed.jld2`에 저장
    + `setting.jl` : seed 구성

**Example**
```julia
include("setting.jl") # 해당 파일을 불러와서 실행
using ProRF

printm("AB dataset start") # Telegram으로 전송
...
rf_model(X, Y, 5, 1000, data_state=data_state, learn_state=learn_state) # 중복된 선언부 없이 해결 가능
...
printm("AB dataset end") # Telegram으로 전송
```
중복되는 부분을 제거해서 코드의 가독성 강화

- 서버용 코드 작성

Dataset의 종류에 따라서 사용하는 함수의 차이를 둘 생각
- `n < 200` avGFPs, DsReds, eqFP578s, RBs Dataset : `iter_get_reg_importance` $\Rightarrow$ `small.jl`
- `n ≥ 200` AB, avGFP, GB1, GB1p, gGB1, Pab1, TDP43, Ube43 Dataset : `get_reg_importance` $\Rightarrow$ `big.jl`

핵심 부분은 서버에 돌리고 시각화 부분은 일반적인 환경에서 볼 수 있음

- Small subset 실행


seed 고정용 (리눅스 설치 후 맨 처음에 실행)
```
julia make_seed.jl
```

small subset 실행  
16개의 vCPU를 가지므로, 5개의 프로세스를 생성하고 3개의 쓰레드를 각각 부여
```
nohup julia -t 3 -p 5 small.jl 1>/dev/null 2>&1 &
```

julia 프로세스 확인 후 종료
```
ps -ef | grep julia
kill -15 [PID]
```

## 7/22
- Big subset 실행

```
nohup julia -t 16 big.jl 1>/dev/null 2>&1 &
```

- Big, Small subset을 읽고 보여줄 수 있는 jupyter notebook 제작
  + `load_big.ipynb` : Big subset
  +  들을 읽을 수 있는 jupyter notebook
  + `load_small.ipynb` : Small subset 들을 읽을 수 있는 jupyter notebook

무거운 작업은 서버에서 작업하고, 사용자 친화적이게 간단한 작업은 Interactive한 환경에서 사용자가 인자를 바꾸어가면서 시각화 가능.

- 과도한 RAM 사용으로 프로세스가 killed 되는 현상

`rf_importance`, `get_reg_importance`, `iter_get_reg_importance`에 `memory_usage` 항목을 추가해서 RAM의 사용량을 조절 할 수 있도록 했음.

- Telegram 알림 버그

Big subset을 실행시키는 과정에서 알 수 없는 버그가 Telegram 메세지를 보내는 과정에서 생기는 문제를 확인하였음. 그래서 수시로 MobaXterm을 이용해 접속해서 프로세스를 확인하는 것으로 대체함.  

따라서 7/21 연구노트에서 Telegram을 사용하는 부분을 삭제함.

## 7/24
- Big subset RAM 조정

ShapML을 이용해서 메모리를 사용하는데 특정 dataset에서 과도하게 사용하는 것을 발견해서 RAM 사용량을 조정할 수 있도록 수정했음.  
사용량 계산 방식을 바꾸든, 조정이 필요할 것 같다.

## 7/25

- 계산 결과 불러오는 방식 변경

`load_save.jl`을 만들어서 내부적으로 처리하도록 하여 사용자가 쉽게 불러올 수 있도록 변경하고, 각각 개별로 파일을 만들고 파일 이름을 얻어서 `dataset_name`에 저장하여 쉽게 `RF` 구조체를 불러올 수 있도록 설계 변경.

- avGFPs dataset 항목 추가

avGFP dataset에서 얻어낸 Feature importance를 합리적으로 비교하기 위해서는 avGFPs에서 같은 항목을 가지고 와야 한다고 생각해서 avGFPs에서 F열을 추가함.

## 7/26

- VSCode를 ssh로 연동하여 사용

상대적으로 시간이 오래 걸릴 수 있는 작업 들을 서버에서 연동시키셔 쉽게 사용.

## 7/27

- 특정 set에 대한 분석 진행
  
논문에 나와있는 다양한 정보를 동시에 체계적으로 분석하기 위해서 같은 단백질에 대한 분석을 동시에 진행하는 .ipynb 제작.