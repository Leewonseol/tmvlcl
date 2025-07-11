# 필요한 라이브러리 로드
library(dplyr)
library(ggplot2)

# --- 1. 모델 설정: 조작적 정의 및 확률 ---

# 시뮬레이션 기본 정보
n_simulations <- 100000
n_competitors <- 13
positions <- 5

# 경쟁자가 충분한 자원을 보유하고 있을 확률
prob_has_resources <- 0.5

# [자원 보유 시] 경쟁자의 세부 항목별 성공 확률
probs_with_resources <- c(
   pass_1_1 = 0.20,  # 정의 1-1: 맞춤형 관심(지원 전공 분야의 교수 이름, 저서, 혹은 구체적인 연구 분야를 단 한 번이라도 언급했는가?)
  pass_1_2 = 0.30,  # 정의 1-2: 논리적 연결성(자신의 지원 동기를 설명할 때, 자신의 과거 경험과 지원 학과의 특성을 명확한 인과관계로 연결하여 설명했는가?)
  pass_1_3 = 0.10,  # 정의 1-3: 정보 탐색(면접 대화 중에, 학교의 커리큘럼, 특성, 혹은 인재상 등 사전에 조사하지 않으면 알기 어려운 정보를 자연스럽게 언급하거나, 이를 기반으로 질문했는가?)
  # --- 관문 2: 심층 역량 및 진실성 ---
  pass_2_1 = 0.10,  # 정의 2-1: 압박 검증 대응 (자신이 공부했다고 말한 특정 이론/경험에 대해 교수가 기습적으로 질문했을 때, 관련된 핵심 개념이나 학자 이름을 포함한 답변을 했는가?)
  pass_2_2 = 0.05,  # 정의 2-2: 적용 및 확장 능력 (단순히 이론을 설명하는 데 그치지 않고, 그것을 구체적인 사례 혹은 자신의 자기 성찰과 연결하여 한 단계 더 나아간 생각을 보여주었는가?)
  pass_2_3 = 0.10   # 정의 2-3: 메타인지 및 성찰 (자신의 답변이 완벽하지 않다는 것을 인지했을 때, 그것을 포기하거나 얼버무리는 대신, 스스로의 한계를 인정하거나 성찰적인 태도를 보이며 대화를 마무리했는가?) 
)
# [자원 미보유 시] 경쟁자의 세부 항목별 성공 확률
probs_without_resources <- c(
  # --- 관문 1: 기본 준비 및 진정성 ---
  pass_1_1 = 0.20,  # 정의 1-1: 맞춤형 관심(지원 전공 분야의 교수 이름, 저서, 혹은 구체적인 연구 분야를 단 한 번이라도 언급했는가?)
  pass_1_2 = 0.30,  # 정의 1-2: 논리적 연결성(자신의 지원 동기를 설명할 때, 자신의 과거 경험과 지원 학과의 특성을 명확한 인과관계로 연결하여 설명했는가?)
  pass_1_3 = 0.10,  # 정의 1-3: 정보 탐색(면접 대화 중에, 학교의 커리큘럼, 특성, 혹은 인재상 등 사전에 조사하지 않으면 알기 어려운 정보를 자연스럽게 언급하거나, 이를 기반으로 질문했는가?)
  # --- 관문 2: 심층 역량 및 진실성 ---
  pass_2_1 = 0.10,  # 정의 2-1: 압박 검증 대응 (자신이 공부했다고 말한 특정 이론/경험에 대해 교수가 기습적으로 질문했을 때, 관련된 핵심 개념이나 학자 이름을 포함한 답변을 했는가?)
  pass_2_2 = 0.05,  # 정의 2-2: 적용 및 확장 능력 (단순히 이론을 설명하는 데 그치지 않고, 그것을 구체적인 사례 혹은 자신의 자기 성찰과 연결하여 한 단계 더 나아간 생각을 보여주었는가?)
  pass_2_3 = 0.10   # 정의 2-3: 메타인지 및 성찰 (자신의 답변이 완벽하지 않다는 것을 인지했을 때, 그것을 포기하거나 얼버무리는 대신, 스스로의 한계를 인정하거나 성찰적인 태도를 보이며 대화를 마무리했는가?) 
)


# --- 2. 몬테카를로 시뮬레이션 실행 ---
your_prob_results <- numeric(n_simulations)
pb <- txtProgressBar(min = 0, max = n_simulations, style = 3)

for (i in 1:n_simulations) {
  
  competitor_survivors_count <- 0
  
  for (j in 1:n_competitors) {
    
    # 1단계: 해당 경쟁자가 자원을 보유했는지 결정
    has_resources <- rbinom(1, 1, prob = prob_has_resources) == 1
    
    # 2단계: 자원 보유 여부에 따라 이번 경쟁자의 통과 확률 세트 결정
    current_probs <- if (has_resources) probs_with_resources else probs_without_resources
    
    # --- 관문 1 평가 (통과 기준: 3개 중 2개 이상 성공) ---
    g1_outcomes <- rbinom(3, 1, prob = current_probs[c("pass_1_1", "pass_1_2", "pass_1_3")])
    passed_g1 <- sum(g1_outcomes) >= 2
    
    if (!passed_g1) next # G1 탈락 시 다음 경쟁자로
    
    # --- 관문 2 평가 (통과 기준: 핵심(2-1) 성공 AND 추가(2-2, 2-3) 중 1개 이상 성공) ---
    passed_g2_core <- rbinom(1, 1, prob = current_probs["pass_2_1"]) == 1
    additional_outcomes <- rbinom(2, 1, prob = current_probs[c("pass_2_2", "pass_2_3")])
    passed_g2_additional <- sum(additional_outcomes) >= 1
    
    if (!(passed_g2_core && passed_g2_additional)) next # G2 탈락 시 다음 경쟁자로
    
    # 두 관문을 모두 통과한 경우에만 최종 생존자로 카운트
    competitor_survivors_count <- competitor_survivors_count + 1
  }
  
  # 최종 생존자 수 = 나(1명) + 생존한 경쟁자 수
  total_survivors <- 1 + competitor_survivors_count
  
  # 나의 합격 확률 계산 및 저장
  your_prob_results[i] <- min(1, positions / total_survivors)
  
  setTxtProgressBar(pb, i)
}
close(pb)

# --- 3. 최종 결과 분석 및 출력 ---
final_avg_probability <- mean(your_prob_results)

cat("\n--- 자원 기반 최종 시뮬레이션 결과 ---\n")
cat("총", n_simulations, "번의 가상 면접 시뮬레이션 결과...\n\n")
cat("귀하의 최종 합격 확률(기댓값):", round(final_avg_probability * 100, 2), "%\n")
