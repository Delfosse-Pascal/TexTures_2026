(function () {
  const root = document.documentElement;
  const savedTheme = localStorage.getItem("textures-theme");
  if (savedTheme) root.dataset.theme = savedTheme;

  function ensureHeaderMenu() {
    const header = document.querySelector("body > header");
    if (!header) return;
    const hasExternalMenu = Array.from(header.children).some((child) => child.dataset.localMenu !== "fallback");
    if (hasExternalMenu) {
      const fallback = header.querySelector('[data-local-menu="fallback"]');
      if (fallback) fallback.remove();
      return;
    }
    if (!header.querySelector('[data-local-menu="fallback"]')) {
      header.insertAdjacentHTML("beforeend", '<nav data-local-menu="fallback" aria-label="Menu local"><ul><li><a href="' + localHomeHref() + '">Accueil</a></li><li><a href="' + localHomeHref() + '#galeries">Galeries</a></li><li><a href="' + localHomeHref() + '#musique">Musique</a></li></ul></nav>');
    }
  }

  function localHomeHref() {
    const home = document.querySelector(".home-button");
    return home ? home.getAttribute("href") : "index.html";
  }

  function toggleTheme() {
    const next = root.dataset.theme === "dark" ? "light" : "dark";
    root.dataset.theme = next;
    localStorage.setItem("textures-theme", next);
  }

  const lightbox = document.querySelector("[data-lightbox]");
  const stage = document.querySelector("[data-lightbox-stage]");
  const caption = document.querySelector(".lightbox-caption");
  let activeAudio = null;
  let activeAudioButton = null;

  function resetAudioButton(button) {
    if (!button) return;
    button.classList.remove("is-playing");
    button.textContent = button.classList.contains("home-music") ? "Musique" : "Lancer la musique";
    button.setAttribute("aria-pressed", "false");
  }

  function stopActiveAudio() {
    if (activeAudio) {
      activeAudio.pause();
      activeAudio.currentTime = 0;
      activeAudio = null;
    }
    resetAudioButton(activeAudioButton);
    activeAudioButton = null;
  }

  function getAudioForButton(button) {
    const localAudio = button.parentElement ? button.parentElement.querySelector(".inline-audio") : null;
    if (localAudio) return localAudio;
    const src = button.dataset.audioSrc;
    if (!src) return null;
    const audio = document.createElement("audio");
    audio.className = "inline-audio";
    audio.hidden = true;
    audio.preload = "none";
    audio.src = src;
    button.insertAdjacentElement("afterend", audio);
    return audio;
  }

  function toggleAudio(button) {
    const audio = getAudioForButton(button);
    if (!audio) return;
    if (activeAudioButton === button && activeAudio && !activeAudio.paused) {
      stopActiveAudio();
      return;
    }
    stopActiveAudio();
    activeAudio = audio;
    activeAudioButton = button;
    button.classList.add("is-playing");
    button.textContent = "Arreter la musique";
    button.setAttribute("aria-pressed", "true");
    activeAudio.addEventListener("ended", stopActiveAudio, { once: true });
    activeAudio.play().catch(() => {
      stopActiveAudio();
      resetAudioButton(button);
    });
  }

  function bindAudioButtons() {
    document.querySelectorAll("[data-audio-toggle]").forEach((button) => {
      if (button.dataset.audioBound === "true") return;
      button.dataset.audioBound = "true";
      button.setAttribute("aria-pressed", "false");
      button.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        toggleAudio(button);
      });
    });
  }

  function closeLightbox() {
    if (!lightbox || !stage) return;
    stage.querySelectorAll("audio, video").forEach((media) => media.pause());
    stage.innerHTML = "";
    lightbox.hidden = true;
    document.body.style.overflow = "";
  }

  function openLightbox(src, type, text) {
    if (!lightbox || !stage) return;
    stage.innerHTML = "";
    let element;
    if (type === "audio") {
      element = document.createElement("audio");
      element.controls = true;
      element.autoplay = false;
      element.src = src;
    } else if (type === "video") {
      element = document.createElement("video");
      element.controls = true;
      element.autoplay = false;
      element.src = src;
    } else {
      element = document.createElement("img");
      element.src = src;
      element.alt = text || "Image agrandie";
    }
    stage.appendChild(element);
    if (caption) caption.textContent = text || "";
    lightbox.hidden = false;
    document.body.style.overflow = "hidden";
    if (type === "audio" || type === "video") element.focus();
  }

  document.addEventListener("click", (event) => {
    const themeButton = event.target.closest("[data-theme-toggle]");
    if (themeButton) {
      toggleTheme();
      return;
    }

    const closeButton = event.target.closest("[data-lightbox-close]");
    if (closeButton || event.target === lightbox) {
      closeLightbox();
      return;
    }

    const opener = event.target.closest("[data-lightbox-src]");
    if (opener) {
      openLightbox(opener.dataset.lightboxSrc, opener.dataset.lightboxType || "image", opener.dataset.lightboxCaption || "");
    }
  }, true);

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeLightbox();
  });

  window.addEventListener("beforeunload", stopActiveAudio);

  bindAudioButtons();
  ensureHeaderMenu();
  const header = document.querySelector("body > header");
  if (header) {
    const observer = new MutationObserver(() => ensureHeaderMenu());
    observer.observe(header, { childList: true });
  }
})();