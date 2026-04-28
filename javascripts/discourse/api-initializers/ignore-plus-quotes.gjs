import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const hideQuotes = settings.hide_ignored_user_quotes;
  const hideAvatarsInPosts = settings.hide_ignored_users_avatar;

  if (!hideQuotes && !hideAvatarsInPosts) return;

  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsers = user.ignored_users;
  if (!ignoredUsers?.length) return;

  function isIgnoredUser(username) {
    if (!username) return false;
    return ignoredUsers.some(
      (ignored) => ignored.toLowerCase() === username.toLowerCase()
    );
  }

  api.decorateCookedElement(
    (element) => {
      if (!hideQuotes) return;

      const quotes = element.querySelectorAll("aside.quote");

      quotes.forEach((quote) => {
        const username = quote.getAttribute("data-username");

        if (username && isIgnoredUser(username)) {
          quote.classList.add("ignored-user-quote");

          const placeholder = document.createElement("div");
          placeholder.className = "ignored-quote-placeholder";

          placeholder.innerHTML = `
            <span class="ignored-quote-message">
              <svg class="fa d-icon d-icon-eye-slash svg-icon svg-string" xmlns="http://www.w3.org/2000/svg">
                <use href="#eye-slash"></use>
              </svg>
              Conteúdo de um usuário ignorado
            </span>
          `;

          quote.style.display = "none";

          quote.parentNode.insertBefore(placeholder, quote);
        }
      });
    },
    {
      id: "ignore-plus-quotes",
      onlyStream: true,
    }
  );

  api.decorateCookedElement(
    (element) => {
      if (!hideAvatarsInPosts) return;

      const avatars = element.querySelectorAll(".avatar, img.avatar");

      avatars.forEach((avatar) => {
        const username =
          avatar.getAttribute("data-username") ||
          avatar.getAttribute("title") ||
          avatar.closest("[data-username]")?.getAttribute("data-username");

        if (username && isIgnoredUser(username)) {
          avatar.classList.add("ignored-user-avatar");
        }
      });
    },
    {
      id: "ignore-plus-avatars",
    }
  );
});
