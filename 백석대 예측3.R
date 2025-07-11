library(dplyr)
library(ggplot2)

# --- 1. 시나리오 설정 ---
n_simulations <- 100000
n_competitors <- 13
positions <- 5

# GPA 패널티 시나리오
gpa_penalty_cases <- c(1.0, 0.5, 0.5) # 경쟁자용 (1~3번 케이스)
your_gpa_penalty_vec <- ifelse(runif(n_simulations) < 0.99, 0.0, 1.0) # 99% 탈락, 1% 생존

# 각 세부항목별 능력치 분포 파라미터 설정 (pass_1_1에 정보탐색 통합)
skill_distributions <- list(
  pass_1_1 = c(4, 2),   # 맞춤형 관심 + 정보탐색(통합)
  pass_1_2 = c(5, 2),   # 논리적 연결성
  pass_2_1 = c(2.5, 4), # 압박 검증 대응
  pass_2_2 = c(2, 6),   # 적용 및 확장
  pass_2_3 = c(2.5, 2.5)# 메타인지
)

your_prob_results <- numeric(n_simulations)
pb <- txtProgressBar(min = 0, max = n_simulations, style = 3)

for (i in 1:n_simulations) {
  competitor_gpa_penalties <- sample(gpa_penalty_cases, n_competitors, replace = TRUE)
  survivor_penalties <- numeric(0)
  # 경쟁자 평가 (관문 통과자만 패널티 집계)
  for (j in 1:n_competitors) {
    current_probs <- sapply(skill_distributions, function(params) {
      rbeta(1, shape1 = params[1], shape2 = params[2])
    })
    # 관문 1: pass_1_1(통합), pass_1_2 모두 성공해야 통과
    g1_1 <- rbinom(1, 1, prob = current_probs["pass_1_1"])
    g1_2 <- rbinom(1, 1, prob = current_probs["pass_1_2"])
    passed_g1 <- (g1_1 == 1) & (g1_2 == 1)
    if (!passed_g1) next
    # 관문 2: 핵심(2-1) 성공 AND 추가(2-2, 2-3) 중 1개 이상 성공
    passed_g2_core <- rbinom(1, 1, prob = current_probs["pass_2_1"]) == 1
    additional_outcomes <- rbinom(2, 1, prob = current_probs[c("pass_2_2", "pass_2_3")])
    passed_g2_additional <- sum(additional_outcomes) >= 1
    if (!(passed_g2_core && passed_g2_additional)) next
    survivor_penalties <- c(survivor_penalties, competitor_gpa_penalties[j])
  }
  # 나 자신도 관문을 통과했는지 시뮬레이션
  my_probs <- sapply(skill_distributions, function(params) {
    rbeta(1, shape1 = params[1], shape2 = params[2])
  })
  my_g1_1 <- rbinom(1, 1, prob = my_probs["pass_1_1"])
  my_g1_2 <- rbinom(1, 1, prob = my_probs["pass_1_2"])
  my_passed_g1 <- (my_g1_1 == 1) & (my_g1_2 == 1)
  my_passed_g2_core <- rbinom(1, 1, prob = my_probs["pass_2_1"]) == 1
  my_additional <- rbinom(2, 1, prob = my_probs[c("pass_2_2", "pass_2_3")])
  my_passed_g2_additional <- sum(my_additional) >= 1

  my_penalty <- your_gpa_penalty_vec[i]

  if (my_passed_g1 && my_passed_g2_core && my_passed_g2_additional) {
    survivor_penalties <- c(survivor_penalties, my_penalty)
    survivors_with_penalty <- survivor_penalties[survivors_with_penalty > 0]
    n_final_survivors <- length(survivors_with_penalty)
    if (my_penalty == 0) {
      your_prob_results[i] <- 0
    } else if (n_final_survivors <= positions) {
      your_prob_results[i] <- 1.0
    } else {
      your_prob_results[i] <- (positions / n_final_survivors)
    }
  } else {
    your_prob_results[i] <- 0
  }
  setTxtProgressBar(pb, i)
}
close(pb)

# --- 3. 최종 결과 분석 및 출력 ---
final_avg_probability <- mean(your_prob_results)
risk_scenario_count <- sum(your_prob_results < 1.0)
risk_probability <- risk_scenario_count / n_simulations

cat("\n--- 궁극의 비관적 시나리오 최종 시뮬레이션 결과 ---\n")
cat("총", n_simulations, "번의 가상 면접 시뮬레이션 결과...\n\n")
cat("1. 귀하의 최종 합격 확률(기댓값):", round(final_avg_probability * 100, 2), "%\n")
cat("2. '리스크 시나리오' 발생 확률:", round(risk_probability * 100, 2), "%\n")

# --- 4. 시각화: 합격 여부 막대그래프 ---
your_pass_result <- ifelse(your_prob_results > 0, 1, 0)
df_result <- data.frame(pass = factor(your_pass_result, levels = c(0, 1), labels = c("불합격", "합격")))

ggplot(df_result, aes(x = pass)) +
  geom_bar(aes(y = (..count..) / sum(..count..)), fill = "skyblue", color = "black", width = 0.5) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "합격/불합격 비율 (몬테카를로 시뮬레이션)",
       x = "결과", y = "비율") +
  theme_minimal(base_size = 14)
