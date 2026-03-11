import os
import re

lib_dir = os.path.join('catatcuan-mobile', 'lib')

# Regex to find ScaffoldMessenger.of(context).showSnackBar(...)
# This is a bit tricky because of nested parentheses.
# We'll use a stack-based approach or a more robust regex if possible.
# Actually, since Dart code is quite structured, we might just parse it manually or use a regex with cautious limits.

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'ScaffoldMessenger.of(context).showSnackBar' not in content:
        return False

    # Inject import
    import_statement = "import 'package:catatcuan_mobile/core/utils/app_toast.dart';"
    if import_statement not in content:
        # Find the last import
        imports = re.findall(r"^import\s+['\"][^'\"]*['\"];", content, re.MULTILINE)
        if imports:
            last_import = imports[-1]
            content = content.replace(last_import, f"{last_import}\n{import_statement}", 1)

    # We will do a basic string replacement by finding the blocks.
    # We look for "ScaffoldMessenger.of(context).showSnackBar("
    
    out_content = ""
    idx = 0
    while True:
        start_idx = content.find('ScaffoldMessenger.of(context).showSnackBar(', idx)
        if start_idx == -1:
            out_content += content[idx:]
            break
            
        out_content += content[idx:start_idx]
        
        # Find the matching closing parenthesis
        open_parens = 0
        end_idx = start_idx + len('ScaffoldMessenger.of(context).showSnackBar(')
        while end_idx < len(content):
            if content[end_idx] == '(':
                open_parens += 1
            elif content[end_idx] == ')':
                if open_parens == 0:
                    break
                open_parens -= 1
            end_idx += 1
            
        snippet = content[start_idx:end_idx+1]
        
        # Extract message
        msg_match = re.search(r"Text\((['\"])(.*?)\1\)", snippet)
        message = msg_match.group(2) if msg_match else "Pesan"
        
        # Determine type
        toast_type = 'showInfo'
        if 'error' in snippet.lower() or 'red' in snippet.lower() or 'gagal' in snippet.lower():
            toast_type = 'showError'
        elif 'orange' in snippet.lower() or 'warning' in snippet.lower() or 'kosong' in snippet.lower() or 'pilih' in snippet.lower() or 'wajib' in snippet.lower():
            toast_type = 'showWarning'
        elif 'berhasil' in snippet.lower() or 'success' in snippet.lower() or 'primary' in snippet.lower():
            toast_type = 'showSuccess'
            
        replacement = f"AppToast.{toast_type}(context, '{message}')"
        out_content += replacement
        
        idx = end_idx + 1

    if content != out_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(out_content)
        return True
    return False

changed_files = []
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            if process_file(path):
                changed_files.append(path)

print(f"Changed {len(changed_files)} files: {changed_files}")
