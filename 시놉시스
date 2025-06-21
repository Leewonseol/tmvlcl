import streamlit as st
import difflib
import time
import re
from openai import OpenAI

# 🔑 Streamlit Secrets를 사용한 안전한 API 키 관리
# 배포 시 Streamlit 클라우드에 secrets를 설정해야 합니다.
try:
    client = OpenAI(api_key=st.secrets["OPENAI_API_KEY"])
except Exception:
    st.error("OpenAI API 키를 설정해주세요. 로컬에서 실행하는 경우 .streamlit/secrets.toml 파일이 필요합니다.")
    st.stop()


# 🎯 시나리오 생성 함수 (최신 OpenAI 라이브러리 적용)
def generate_script(synopsis):
    prompt = f"""
당신은 전문 시나리오 작가입니다. 사용자로부터 받은 시놉시스를 바탕으로, 영상 전문 용어(S#, 촬영 기법 등)를 사용하여 구체적이고 생생한 장면 중심의 시나리오를 작성해주세요.

[사용자 시놉시스]
{synopsis}
"""
    try:
        response = client.chat.completions.create(
            model="gpt-4o",  # 최신 모델 사용 권장
            messages=[{"role": "user", "content": prompt}]
        )
        return response.choices[0].message.content
    except Exception as e:
        st.error(f"시나리오 생성 중 오류가 발생했습니다: {e}")
        return None

# 🧮 편집 통계 계산 함수 (수정 없음)
def calculate_edit_stats(original, edited):
    orig_words = original.split()
    edit_words = edited.split()

    sm = difflib.SequenceMatcher(None, orig_words, edit_words)
    opcodes = sm.get_opcodes()

    deleted = sum(i2 - i1 for tag, i1, i2, _, _ in opcodes if tag == 'delete')
    inserted = sum(j2 - j1 for tag, _, _, j1, j2 in opcodes if tag == 'insert')
    total = len(orig_words)

    d = deleted / total if total > 0 else 0
    r = inserted / total if total > 0 else 0
    e = (deleted + inserted) / total if total > 0 else 0

    return d, r, e

# 📊 베이지안 만족도 추정 함수 (수정 없음)
def bayesian_satisfaction(d, r, e, p_m1=0.5, p_m0=0.5):
    likelihood_m1 = (1 - d**2) * (1 - r**1.5) * (1 - e)
    likelihood_m0 = (d**1.2) * (r**1.3) * e

    p1 = p_m1 * likelihood_m1
    p0 = p_m0 * likelihood_m0
    # 0으로 나누기 방지
    return p1 / (p1 + p0 + 1e-9)

# 🎞️ 시나리오에서 장면 설명 추출 함수 (✨ 신규 추가)
def parse_scenario_for_scenes(scenario_text):
    # 정규 표현식을 사용하여 S# 또는 '장면'으로 시작하는 줄을 찾습니다.
    # 각 장면의 내용을 포함하여 추출합니다.
    scenes = re.findall(r"^(S#\d+|장면 \d+)\..*?(?=\nS#\d+|\n장면 \d+|\Z)", scenario_text, re.MULTILINE | re.DOTALL)
    
    # 추출된 장면 설명에서 이미지 생성에 적합한 프롬프트로 가공합니다.
    prompts = []
    for scene in scenes:
        # 지문 위주로 프롬프트를 생성 (대사 제외)
        action_description = re.sub(r'\(.*?\)|".*?"', '', scene).strip()
        # 프롬프트를 좀 더 DALL-E에 친화적으로 만듭니다.
        prompt = f"cinematic film still, {action_description}, detailed, high quality"
        prompts.append(prompt)

    # 만약 추출된 장면이 없다면, 전체 텍스트를 요약하여 프롬프트를 생성할 수도 있습니다.
    if not prompts and scenario_text:
        prompts.append(f"cinematic film still, a key scene from a story about: {scenario_text[:200]}, detailed, high quality")

    return prompts


# 🧑‍🎨 이미지 생성 함수 (최신 OpenAI 라이브러리 적용)
def generate_images(scene_prompts):
    urls = []
    if not scene_prompts:
        st.warning("이미지로 생성할 장면을 찾을 수 없습니다. 시나리오에 'S#1.' 또는 '장면 1.'과 같은 형식을 사용해주세요.")
        return []
    
    with st.spinner(f"{len(scene_prompts)}개의 스토리보드 이미지를 생성 중입니다..."):
        for prompt in scene_prompts:
            try:
                response = client.images.generate(
                    model="dall-e-3",
                    prompt=prompt,
                    n=1,
                    size="1024x1024",
                    quality="standard" # standard or hd
                )
                url = response.data[0].url
                # 원본 프롬프트에서 핵심 설명만 caption으로 사용
                caption = prompt.replace("cinematic film still,", "").replace(", detailed, high quality", "").strip()
                urls.append((caption, url))
            except Exception as e:
                st.error(f"이미지 생성 중 오류가 발생했습니다: {prompt} - {e}")
                continue
    return urls

# --------------------------------------------------------------------------
# 🎛️ Streamlit UI
# --------------------------------------------------------------------------

st.set_page_config(layout="wide")
st.title("🎬 AI 표현영화치료 시스템")
st.markdown("시놉시스를 입력하면 AI가 시나리오 초안을 생성합니다. 시나리오를 자유롭게 편집하고, AI가 추정한 만족도를 확인해보세요. 마지막으로, 완성된 시나리오를 기반으로 한 스토리보드 이미지를 생성할 수 있습니다.")

# 세션 상태 초기화
if 'original_scenario' not in st.session_state:
    st.session_state['original_scenario'] = ""
if 'edited_scenario' not in st.session_state:
    st.session_state['edited_scenario'] = ""

col1, col2 = st.columns(2)

with col1:
    st.subheader("1. 시놉시스 입력")
    user_synopsis = st.text_area("📝 주제, 기획의도, 등장인물, 줄거리를 포함하여 자유롭게 작성하세요.", height=200, placeholder="예: 주제는 상실과 회복. 한 중년 남자가 반려견을 잃은 후, 낯선 소녀와의 만남을 통해 삶의 의미를 되찾는 이야기.")

    if st.button("▶ 시나리오 초안 생성하기", type="primary"):
        if user_synopsis:
            with st.spinner("GPT-4o가 시나리오를 작성 중입니다..."):
                scenario = generate_script(user_synopsis)
                if scenario:
                    st.session_state['original_scenario'] = scenario
                    st.session_state['edited_scenario'] = scenario # 편집본도 초기화
        else:
            st.warning("시놉시스를 입력해주세요.")

with col2:
    st.subheader("2. 시나리오 편집 및 만족도 분석")
    edited_text = st.text_area("🖊️ 생성된 시나리오를 자유롭게 편집하세요.", value=st.session_state.get('edited_scenario', ''), height=300, key="edited_scenario_area")
    
    # 사용자가 편집하면 st.session_state 업데이트
    st.session_state['edited_scenario'] = edited_text

    if st.session_state['original_scenario']:
        if st.button("🔍 편집 만족도 추정하기"):
            original = st.session_state['original_scenario']
            edited = st.session_state['edited_scenario']
            
            d, r, e = calculate_edit_stats(original, edited)
            prob = bayesian_satisfaction(d, r, e)
            
            st.metric("🧠 AI가 추정한 만족도 확률", f"{prob*100:.1f}%")
            if prob >= 0.7:
                st.success("✔️ 만족스러운 결과물에 가까워진 것 같습니다! 편집을 통해 시나리오가 발전하고 있습니다.")
            elif prob < 0.3:
                st.error("🚨 수정이 많이 필요해 보입니다. AI에게 다른 버전의 시나리오를 요청하거나, 편집을 계속 진행해보세요.")
            else:
                st.warning("🔁 편집이 진행 중입니다. 더 나은 결과를 위해 계속 다듬어보세요.")

st.divider()

st.subheader("3. 시나리오 기반 스토리보드 생성")

if st.button("🖼️ 현재 시나리오로 스토리보드 생성하기"):
    scenario_text = st.session_state.get('edited_scenario', '')
    if scenario_text:
        scene_prompts = parse_scenario_for_scenes(scenario_text)
        image_results = generate_images(scene_prompts)
        
        if image_results:
            # 2열로 이미지 표시
            img_cols = st.columns(2)
            for i, (caption, url) in enumerate(image_results):
                with img_cols[i % 2]:
                    st.image(url, caption=f"S#{i+1}: {caption}", use_column_width=True)
    else:
        st.warning("먼저 시나리오를 생성하거나 입력해주세요.")
