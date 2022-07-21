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
Pkg.add("Telegram")
Pkg.add("JLD2")
```

- 기본적인 workflow 구성
    + `make_seed.jl` : seed 생성 후에 `Save/seed.jld2`에 저장
    + `setting.jl` : Telegram bot 연결, seed 구성
      + `Save/telegram.txt` : Telegram bot token과 id가 엔터로 구분되어 있는 텍스트 파일

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
julia -t 16 big.jl 1>/dev/null 2>&1 &
```

- Big, Small subset을 읽고 보여줄 수 있는 jupyter notebook 제작
  + `load_big.ipynb` : Big subset 들을 읽을 수 있는 jupyter notebook
  + `load_small.ipynb` : Small subset 들을 읽을 수 있는 jupyter notebook

무거운 작업은 서버에서 작업하고, 사용자 친화적이게 간단한 작업은 Interactive한 환경에서 사용자가 인자를 바꾸어가면서 시각화 가능.