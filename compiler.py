from pathlib import Path
import re
import subprocess
from openai import OpenAI

# Client OpenAI local (Ollama / vLLM / LM Studio)
client = OpenAI(base_url="http://localhost:11434/v1", api_key="ollama")
MODEL_NAME = "qwen2.5-coder:7b"
SPECS_DIR = Path("specs")


def parse_target_path(spec_file: Path) -> Path:
    """Extrait le fichier cible depuis la ligne '# Target: ...'."""
    content = spec_file.read_text(encoding="utf-8")
    match = re.search(
        r"^#\s*Target:\s*(.+)$", content, re.MULTILINE | re.IGNORECASE
    )
    if match:
        return Path(match.group(1).strip())

    clean_stem = re.sub(r"^\d+_", "", spec_file.stem)
    return (
        Path("src") / f"{clean_stem}.py"
        if clean_stem != "main"
        else Path("main.py")
    )


if __name__ == "__main__":
    try:
        subprocess.run(["ruff", "--version"], capture_output=True, check=True)
    except (subprocess.SubprocessError, FileNotFoundError):
        print("⚠️ 'ruff' est manquant. Installez-le via : pip install ruff")
        exit(1)

    if not SPECS_DIR.exists():
        print(f"⚠️ Le dossier '{SPECS_DIR}' n'existe pas. Créez-le.")
        exit(1)

    spec_files = sorted(SPECS_DIR.glob("*.feature"))
    if not spec_files:
        print(f"⚠️ Aucun fichier .feature trouvé dans '{SPECS_DIR}/'")
        exit(1)

    generated_context: dict[str, str] = {}

    for spec_file in spec_files:
        target_path = parse_target_path(spec_file)
        gherkin_content = spec_file.read_text(encoding="utf-8")

        print(
            f"⚡ Compilation LLM de {spec_file.name} ➔ {target_path}..."
        )

        prompt = (
            f"You are a Python compiler. Output ONLY valid executable Python code for '{target_path}'.\n"
            "DO NOT wrap your response in JSON.\n"
            "DO NOT use markdown code blocks (```python ... ```).\n"
            "Implement all features and scenarios described in the Gherkin specification below.\n\n"
            f"GHERKIN SPECIFICATION:\n{gherkin_content}\n\n"
            f"PROJECT CONTEXT (Previously compiled modules):\n{generated_context}"
        )

        response = client.chat.completions.create(
            model=MODEL_NAME,
            temperature=0.0,
            messages=[{"role": "user", "content": prompt}],
        )

        raw_code = response.choices[0].message.content.strip()

        # Nettoyage des blocs markdown
        if raw_code.startswith("```"):
            lines = raw_code.splitlines()
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].startswith("```"):
                lines = lines[:-1]
            raw_code = "\n".join(lines)

        # Écriture du fichier destination
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_text(raw_code, encoding="utf-8")

        # Formatage & Linting
        subprocess.run(["ruff", "format", str(target_path)], capture_output=True)
        subprocess.run(
            [
                "ruff",
                "check",
                "--select",
                "E,F",
                "--fix",
                "--ignore",
                "E501",
                str(target_path),
            ],
            capture_output=True,
        )

        # Mise à jour du contexte projet avec le code nettoyé
        final_code = target_path.read_text(encoding="utf-8")
        generated_context[str(target_path)] = final_code

        print(f"  ✅ {target_path} compilé et nettoyé par Ruff.")

    print("\n🎉 Compilation du projet terminée avec succès !")
