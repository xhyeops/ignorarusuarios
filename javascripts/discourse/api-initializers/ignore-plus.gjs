import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.34", (api) => {
  const hideAvatar = settings.hide_ignored_users_avatar;
  const hideTopics = settings.hide_ignored_user_topics;

  const user = api.getCurrentUser();
  if (!user) return;

  const ignoredUsersRaw = user.ignored_users || [];

  const ignoredUsers = ignoredUsersRaw
    .map((u) => {
      if (typeof u === "string") return u;
      return u?.username || u?.name;
    })
    .filter(Boolean)
    .map((u) => u.toLowerCase());

  if (!ignoredUsers.length) return;

  function isIgnoredUser(username) {
    return ignoredUsers.includes(username?.toLowerCase?.());
  }

  function usernameFromLink(link) {
    return (
      link?.getAttribute("data-user-card") ||
      link?.getAttribute("href")?.replace("/u/", "").split("/")[0]
    );
  }

  function fixTopicListPosters() {
    if (!hideAvatar) return;

    document.querySelectorAll("td.posters").forEach((cell) => {
      const links = Array.from(cell.querySelectorAll("a"));

      links.forEach((link) => {
        const username = usernameFromLink(link);

        if (isIgnoredUser(username)) {
          link.remove();
        }
      });

      const remaining = Array.from(cell.querySelectorAll("a"));

      remaining.forEach((link) => {
        link.classList.remove("latest");
        link.querySelector("img.avatar")?.classList.remove("latest");
      });

      const newLatest = remaining[remaining.length - 1];

      if (newLatest) {
        newLatest.classList.add("latest");

        const avatar = newLatest.querySelector("img.avatar");
        if (avatar) {
          avatar.classList.add("latest");
          avatar.title = avatar.title?.replace(
            /Autor\(a\).*$/,
            "Autor(a) mais recente"
          );
        }
      }
    });
  }

  function hideIgnoredPosts() {
    document.querySelectorAll(".topic-post").forEach((post) => {
      const userLink =
        post.querySelector(".topic-avatar a[data-user-card]") ||
        post.querySelector(".names a[data-user-card]") ||
        post.querySelector("a[data-user-card]");

      const username = usernameFromLink(userLink);

      if (isIgnoredUser(username)) {
        post.style.display = "none";
      }
    });
  }

  function run() {
    fixTopicListPosters();
    hideIgnoredPosts();
  }

  api.onPageChange(() => {
    setTimeout(run, 300);
    setTimeout(run, 1000);
    setTimeout(run, 2000);
  });

  new MutationObserver(() => {
    run();
  }).observe(document.body, {
    childList: true,
    subtree: true,
  });
});
