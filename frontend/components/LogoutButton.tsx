"use client";

import { useRouter } from "next/navigation";

const LogoutButton: React.FC = () => {
  const router = useRouter();

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      // hapus JWT session
      localStorage.removeItem("token");

      // kalau nanti kamu simpan alamat wallet, bisa dihapus juga:
      // localStorage.removeItem("ethAddress");
    }

    router.push("/");
  };

  return (
    <button
      onClick={handleLogout}
      className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
    >
      Logout
    </button>
  );
};

export default LogoutButton;
