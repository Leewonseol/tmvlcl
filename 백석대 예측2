# 필요한 라이브러리 로드
library(dplyr)
library(ggplot2)

# --- 1. 최종 모델 설정 ---

# 시뮬레이션 기본 정보
n_simulations <- 100000
n_competitors <- 13
positions <- 5

# [신규] 최종 동점자 경쟁 시, 낮은 학점으로 인한 페널티 (95% 페널티 적용)
# 즉, 나의 공정한 확률(fair chance) 중 5%만 인정받는다는 의미
gpa_penalty_factor <- 0.05 

# 13명 경쟁자 프로필 분포 가정
competitor_profile_pool <- c(
  rep("완전체", 1), rep("지식형", 4), rep("기술형", 4), rep("무방비형", 4)
)

# 4개 프로필별 세부항목 성공 확률 매트릭스
profile_probabilities <- list(
  "완전체" = c(pass_1_1=0.9, pass_1_2=0.95, pass_1_3=0.7, pass_2_1=0.85, pass_2_2=0.6, pass_2_3=0.7),
  "지식형" = c(pass_1_1=0.8, pass_1_2=0.9, pass_1_3=0.6, pass_2_1=0.2, pass_2_2=0.1, pass_2_3=0.15),
  "기술형" = c(pass_1_1=0.2, pass_1_2=0.3, pass_1_3=0.1, pass_2_1=0.7, pass_2_2=0.05, pass_2_3=0.5),
  "무방비형" = c(pass_1_1=0.1, pass_1_2=0.3, pass_1_3=0.1, pass_2_1=0.1, pass_2_2=0.05, pass_2_3=0.1)
)

# --- 2. 몬테카를로 시뮬레이션 실행 ---
your_prob_results <- numeric(n_simulations)
risk_scenario_count <- 0
pb <- txtProgressBar(min = 0, max = n_simulations, style = 3)

for (i in 1:n_simulations) {
  
  competitor_survivors_count <- 0
  current_competitors_profiles <- sample(competitor_profile_pool)
  
  for (j in 1:n_competitors) {
    profile_name <- current_competitors_profiles[j]
    current_probs <- profile_probabilities[[profile_name]]
    
    # 관문 1 & 2 통과 로직
    g1_outcomes <- rbinom(3, 1, prob = current_probs[1:3])
    passed_g1 <- sum(g1_outcomes) >= 2
    if (!passed_g1) next
    
    passed_g2_core <- rbinom(1, 1, prob = current_probs[4]) == 1
    additional_outcomes <- rbinom(2, 1, prob = current_probs[5:6])
    passed_g2_additional <- sum(additional_outcomes) >= 1
    if (!(passed_g2_core && passed_g2_additional)) next
    
    competitor_survivors_count <- competitor_survivors_count + 1
  }
  
  total_survivors <- 1 + competitor_survivors_count
  
  # --- 최종 관문 및 리스크 계산 ---
  if (total_survivors <= positions) {
    your_prob_results[i] <- 1.0 
  } else {
    risk_scenario_count <- risk_scenario_count + 1
    
    fair_chance <- positions / total_survivors
    # 95% 페널티 적용
    your_prob_results[i] <- fair_chance * gpa_penalty_factor
  }
  
  setTxtProgressBar(pb, i)
}
close(pb)

# --- 3. 최종 결과 분석 및 출력 ---
final_avg_probability <- mean(your_prob_results)
risk_probability <- risk_scenario_count / n_simulations

cat("\n--- 학점 페널티 95% 적용 최종 시뮬레이션 결과 ---\n")
cat("총", n_simulations, "번의 가상 면접 시뮬레이션 결과...\n\n")
cat("1. 귀하의 최종 합격 확률(기댓값):", round(final_avg_probability * 100, 2), "%\n")
cat("2. '리스크 시나리오' 발생 확률:", round(risk_probability * 100, 2), "%\n")
cat("   (리스크 시나리오: 최종 생존자가 5명을 초과하여, 학점 페널티가 적용되는 경쟁 상황이 발생할 확률)\n")
