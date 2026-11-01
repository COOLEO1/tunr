import glob, os, re
root = os.path.expanduser('~/.pub-cache')
for f in glob.glob(root + '/**/on_audio_query*/**/build.gradle', recursive=True):
    s = open(f).read()
    if 'namespace' not in s:
        s = s.replace('android {', "android {\n    namespace 'com.lucasjosino.on_audio_query'", 1)
    s = re.sub(r'compileSdk(Version)?\s*=?\s*\d+', 'compileSdkVersion 36', s)
    s = re.sub(r'JavaVersion\.VERSION_(1_8|11)', 'JavaVersion.VERSION_17', s)
    s = re.sub(r'jvmTarget\s*=\s*[\'"](1\.8|11)[\'"]', 'jvmTarget = "17"', s)
    open(f, 'w').write(s)
    print('PATCHED', f)
    print(s)
