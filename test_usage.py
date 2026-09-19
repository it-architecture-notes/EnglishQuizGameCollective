import json, re

def get_text_values(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, list):
        for item in obj:
            yield from get_text_values(item)
    elif isinstance(obj, dict):
        for k, v in obj.items():
            if k in ('answer_type', 'image_file_name', 'audio_file1', 'audio_file2', 'question_enter_audio'):
                continue
            yield from get_text_values(v)

def check_usages():
    with open('app/assets/quiz-data/levels/greetings/adults/questions.json') as f:
        data = json.load(f)
    video_text = []
    standalone_text = []
    for q in data.get("levelQuestions", []):
        tpl = q.get("template")
        if tpl == "Chapter":
            continue
        texts = list(get_text_values(q)) # get everything in the whole question block!
        if tpl == "VideoConversation":
            video_text.extend(texts)
        else:
            standalone_text.extend(texts)
    
    v_str = " ".join(video_text).lower()
    s_str = " ".join(standalone_text).lower()
    
    with open('app/assets/quiz-data/levels/greetings/adults/translations.json') as f:
        trans_data = json.load(f)
    
    for item in trans_data.get('translations_list', []):
        w = item['english_word'].lower().strip()
        search_w = w
        if search_w.startswith("to "):
            search_w = search_w[3:]
            
        # strip punctuation from search string for regex
        search_w_clean = re.sub(r'[?!.,]', '', search_w).strip()
        
        in_v = bool(re.search(r'\b' + re.escape(search_w_clean) + r'(?:\b|[?!.,]|$)', v_str))
        in_s = bool(re.search(r'\b' + re.escape(search_w_clean) + r'(?:\b|[?!.,]|$)', s_str))
        print(f"{w:25} Video: {in_v}, Standalone: {in_s}")

check_usages()
