import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  // Get theme settings
  const hideQuotes = settings.hide_ignored_user_quotes;
  const hideAvatarsInPosts = settings.hide_ignored_users_avatar;

  // If both settings are disabled, bail early
  if (!hideQuotes && !hideAvatarsInPosts) {
    return;
  }

  // get current user
  const user = api.getCurrentUser();

  // not logged in, bail
  if (!user) {
    return;
  }

  // get a list of ignored users
  const ignoredUsers = user.ignored_users;

  if (!ignoredUsers?.length) {
    return;
  }

  // Helper function to check if a user is ignored
  function isIgnoredUser(username) {
    if (!username) return false;
    return ignoredUsers.some(
      (ignored) => ignored.toLowerCase() === username.toLowerCase()
    );
  }

  // Decorate posts to hide quotes from ignored users
  api.decorateCookedElement(
    (element, helper) => {
      if (!hideQuotes) {
        return;
      }

      // Find all quotes in the post
      const quotes = element.querySelectorAll("aside.quote");

      quotes.forEach((quote) => {
        const username = quote.getAttribute("data-username");

        if (username && isIgnoredUser(username)) {
          // Hide the quote from ignored user
          quote.classList.add("ignored-user-quote");
          
          // Create a placeholder message
          const placeholder = document.createElement("div");
          placeholder.className = "ignored-quote-placeholder";
          placeholder.innerHTML = `
            <span class="ignored-quote-message">
              <svg class="fa d-icon d-icon-eye-slash svg-icon svg-string" xmlns="http://www.w3.org/2000/svg"><use href="#eye-slash"></use></svg>
              Conteúdo de um usuário ignorado oculto
            </span>
            <button class="btn btn-flat btn-text show-ignored-quote" type="button">
              Mostrar mesmo assim
            </button>
          `;
          
          // Hide original quote
          quote.style.display = "none";
          
          // Insert placeholder before the quote
          quote.parentNode.insertBefore(placeholder, quote);
          
          // Add click handler to show the quote
          const showButton = placeholder.querySelector(".show-ignored-quote");
          if (showButton) {
            showButton.addEventListener("click", () => {
              quote.style.display = "";
              quote.classList.add("ignored-quote-revealed");
              placeholder.remove();
            });
          }
        }
      });
    },
    {
      id: "ignore-plus-quotes",
      onlyStream: true,
    }
  );

  // Also handle avatar hiding in poster lists via post decorating
  api.decorateCookedElement(
    (element, helper) => {
      if (!hideAvatarsInPosts) {
        return;
      }

      // This handles avatars within post content if needed
      const avatars = element.querySelectorAll(".avatar, img.avatar");
      
      avatars.forEach((avatar) => {
        // Try to get username from various attributes
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
