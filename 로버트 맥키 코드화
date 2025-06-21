# 필요 라이브러리 설치
# pip install scikit-learn flask konlpy openai

import json
import re
import math
from flask import Flask, request, jsonify
from konlpy.tag import Okt
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
import numpy as np
import openai

# --- 2. "태깅된 시나리오 데이터"란 무엇인가? (가상 데이터 생성) ---
# 이 부분이 바로 '정답지가 있는 학습 데이터'입니다.
# 각 문장에 대해 전문가가 '인과성', '시간연속성' 등을 미리 태깅(라벨링)해 둔 데이터셋입니다.
tagged_data = [
    ("그 결과 그는 모든 것을 얻었다", "인과성"),
    ("그래서 민준은 떠나기로 결심했다", "인과성"),
    ("갑자기 하늘에서 빛이 쏟아졌다", "우연성"),
    ("문득 그는 오래된 기억을 떠올렸다", "우연성"),
    ("그날 밤, 모든 것이 끝났다", "연속성"),
    ("다음 날 아침이 밝았다", "연속성"),
    ("한편, 3년 전 과거의 모습은 이랬다", "비연속성"),
    ("장면이 바뀌고, 다른 공간에서 이야기가 시작된다", "비연속성"),
]

# 데이터 분리: texts는 문제, labels는 정답
texts, labels = zip(*tagged_data)

# TF-IDF 벡터화: 텍스트를 머신러닝이 이해할 수 있는 숫자 벡터로 변환
vectorizer = TfidfVectorizer()
X = vectorizer.fit_transform(texts)
y = np.array(labels)

# 머신러닝 모델 훈련
# 여기서는 4종류의 라벨을 예측하는 모델을 각각 만들었다고 가정합니다.
# 실제로는 더 많은 데이터와 복잡한 모델이 필요합니다.
causality_model = LogisticRegression().fit(X, (y == '인과성') | (y == '우연성'))
time_model = LogisticRegression().fit(X, (y == '연속성') | (y == '비연속성'))

# -----------------------------------------------------------------

# 1. 고급 NLP 분석기 (KoNLPy 형태소 분석기)
okt = Okt()

# 4. GPT API 설정
# 실제 사용 시에는 본인의 API 키를 입력해야 합니다.
# openai.api_key = "YOUR_OPENAI_API_KEY"


class AdvancedScenarioAnalyzer:
    def __init__(self, vectorizer, causality_model, time_model):
        self.vectorizer = vectorizer
        self.causality_model = causality_model
        self.time_model = time_model
        self.plot_vector = [0.25] * 4 # 초기값

    def analyze(self, scenario_text):
        """실제 ML 모델과 NLP를 사용해 시나리오를 분석합니다."""
        # 1. 고급 NLP (형태소 분석)
        morphs = okt.morphs(scenario_text)
        
        # 2. 실제 ML 모델로 예측
        text_vector = self.vectorizer.transform([scenario_text])
        prob_causality = self.causality_model.predict_proba(text_vector)[0][1] # '인과성'일 확률
        prob_continuous_time = self.time_model.predict_proba(text_vector)[0][1] # '연속성'일 확률
        
        # (단순화) 기타 특성은 키워드 기반으로 계산
        prob_closed_ending = 0.5 + (0.1 * scenario_text.count("마침내")) - (0.1 * scenario_text.count("어떻게 됐을까"))
        prob_consistent_reality = 0.5 + (0.1 * scenario_text.count("현실")) - (0.1 * scenario_text.count("꿈"))

        # 4D 벡터 계산 (이전 코드와 유사하게)
        arc = (prob_causality + prob_continuous_time + prob_consistent_reality + prob_closed_ending) / 4
        mini = ((1 - prob_closed_ending) + (1 - prob_causality)) / 2
        anti = ((1 - prob_causality) + (1 - prob_continuous_time) + (1 - prob_consistent_reality)) / 3
        non = 1 - (len(morphs) / (len(scenario_text.split()) + 1)) # 내용 대비 형태소 비율로 단순화

        raw_scores = [arc, mini, anti, non]
        exp_scores = [np.exp(s * 3) for s in raw_scores]
        self.plot_vector = [s / sum(exp_scores) for s in exp_scores]

        return {
            "plot_vector": {
                "아크플롯": self.plot_vector[0],
                "미니플롯": self.plot_vector[1],
                "안티플롯": self.plot_vector[2],
                "논플롯": self.plot_vector[3],
            },
            "details": {
                "인과성 확률": prob_causality,
                "연속적 시간 확률": prob_continuous_time,
            }
        }

    def generate_gpt_suggestion(self, scenario_text):
        """GPT를 이용해 창의적인 제안을 생성합니다."""
        plot_labels = ["아크플롯", "미니플롯", "안티플롯", "논플롯"]
        dominant_plot = plot_labels[np.argmax(self.plot_vector)]
        
        prompt = f"""
        당신은 천재 시나리오 작가이자 스토리 분석가입니다.
        아래는 한 작가가 현재까지 작성한 시나리오 내용과, 그 구조를 분석한 결과입니다.

        --- 현재 시나리오 ---
        {scenario_text}
        --------------------

        --- 구조 분석 결과 ---
        현재 이 스토리는 '{dominant_plot}' 성향이 가장 강합니다.
        (아크플롯: {self.plot_vector[0]:.0%}, 미니플롯: {self.plot_vector[1]:.0%}, 안티플롯: {self.plot_vector[2]:.0%})
        --------------------

        이 분석 결과를 바탕으로, 작가가 다음에 이어서 쓸 수 있는 아주 창의적이고 구체적인 장면 아이디어 3가지를 제안해주세요.
        각 제안은 현재의 플롯 성향을 강화하거나, 혹은 의도적으로 비트는 방향으로 작성될 수 있습니다.
        """
        
        try:
            # 아래 코드는 실제 API 호출 부분입니다. 실행하려면 유효한 API 키가 필요합니다.
            # response = openai.ChatCompletion.create(
            #     model="gpt-4",
            #     messages=[
            #         {"role": "system", "content": "당신은 천재 시나리오 작가이자 스토리 분석가입니다."},
            #         {"role": "user", "content": prompt}
            #     ]
            # )
            # return response.choices[0].message['content']
            
            # API 키가 없으므로, 시뮬레이션된 응답을 반환합니다.
            return f"[GPT 시뮬레이션 응답]\n'{dominant_plot}' 성향을 강화하기 위한 제안:\n1. (구체적인 장면 아이디어 1)\n2. (구체적인 장면 아이디어 2)\n3. (구체적인 장면 아이디어 3)"

        except Exception as e:
            return f"GPT 제안 생성 중 오류 발생: {e}"


# 3. 웹 UI 연동을 위한 Flask API 서버
app = Flask(__name__)
analyzer = AdvancedScenarioAnalyzer(vectorizer, causality_model, time_model)

@app.route('/analyze', methods=['POST'])
def analyze_scenario():
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({"error": "텍스트를 포함하여 요청해주세요."}), 400
    
    scenario_text = data['text']
    analysis_result = analyzer.analyze(scenario_text)
    
    # GPT 제안 생성 (필요시)
    if data.get('suggest', False):
        suggestion = analyzer.generate_gpt_suggestion(scenario_text)
        analysis_result['suggestion'] = suggestion
        
    return jsonify(analysis_result)

if __name__ == '__main__':
    # 이 파이썬 파일을 실행하면, http://127.0.0.1:5000 주소에서 API 서버가 실행됩니다.
    # 외부 프로그램에서 이 주소로 POST 요청을 보내 시나리오 분석을 할 수 있습니다.
    app.run(debug=True, port=5000)

