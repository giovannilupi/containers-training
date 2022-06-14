#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdlib>
#include <cstring>
#include <cerrno>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <sched.h>

#define ALPINEDIR   "../alpine/"

static void run(int argc, char *argv[]);
static void print_args(int argc, char *argv[]);
static int child_func(void *param);
static bool set_id_map(int host_id, int container_id, int range, const char *filename);

struct params_t {
    int argc;
    char **argv;
    int uid;
    int gid;
};

using namespace std;

int main(int argc, char *argv[])
{
    cout.sync_with_stdio();

    if (argc == 1) {
        cerr << "Missing parameter\n";
        exit(EXIT_FAILURE);
    }
    if (strcmp(argv[1], "run") == 0) {
        run(argc-2, &argv[2]);
    } else {
        cerr << "Incorrect parameters\n";
        exit(EXIT_FAILURE);
    }
    return EXIT_SUCCESS;
}

/*!
 * \brief creates a new namespaced child process that will execute the commands
 *        specified in the arguments
 */
static void run(int argc, char *argv[])
{
    print_args(argc, argv);

    const int stack_size = 65536;

    char *stack = new char[stack_size];
    char *stack_top = stack + stack_size;   // stack grows downward
    // flags for the creation of new namespaces
    int flags = 0;
    flags |= CLONE_NEWUTS;
    flags |= CLONE_NEWUSER;
    flags |= CLONE_NEWNS;
    flags |= CLONE_NEWPID;

    params_t *params = new params_t();
    params->argc = argc;
    params->argv = argv;
    params->uid = getuid();
    params->gid = getgid();

    int child_pid = clone(child_func, stack_top, flags, (void *)params);
    if (child_pid == -1) {
        perror("clone");
    }
    cout << "clone returns child pid " << child_pid << endl;
    cout << "calling waitpid" << endl;
    cout.flush();

    // Wait for "clone" children only
    int wstatus;
    int rc2 = waitpid(child_pid, &wstatus, __WCLONE);
    if (rc2 == -1) {
        perror("waitpitd");
    }
    cout << "waitpid returns " << rc2 << endl;
    cout.flush();
}

/*!
 * \brief prints the arguments with which the function has been invoked,
 *        including the uid and pid of the running process
 */
static void print_args(int argc, char *argv[])
{
    cout << "Running [";
    for (int i = 0; i < argc; ++i) {
        if (i > 0)
            cout << ' ';
        cout << argv[i];
    }
    cout << "] as user " << geteuid() << " in process " << getpid() << endl;
    cout.flush();
}

static int child_func(void *param)
{
    params_t *p = reinterpret_cast<params_t *>(param);
    cout << "In child func: execute " << p->argv[0] << "\n";
    print_args(p->argc, p->argv);
    cout.flush();

    // sets the mapping between a user on the host and one in the container
    set_id_map(p->uid, 0, 1, "/proc/self/uid_map");

    // There is a specific limitation added to unprivileged users since Linux 3.19
    // when attempting to map the user's group(s): they have to forfeit their right
    // to alter supplementary groups. This is usually to prevent an user to remove
    // itself from a group which acts as a deny filter for files with ownership like
    // someuser:denygroup and mode u=rw,g=,o=r.
    // This is documented in user_namespaces(7):
    // Writing "deny" to the /proc/[pid]/setgroups file before writing to
    // /proc/[pid]/gid_map will permanently disable setgroups(2) in a user
    // namespace and allow writing to /proc/[pid]/gid_map without having the
    // CAP_SETGID capability in the parent user namespace.

    ofstream ofs("/proc/self/setgroups");
    ofs << "deny";
    ofs.close();

    set_id_map(p->gid, 0, 1, "/proc/self/gid_map");
#if 1
    if (chroot(ALPINEDIR) != 0) {
        perror("chroot to " ALPINEDIR " failed");
    } else {
        cout << "chroot " << ALPINEDIR << " successful\n";
    }
    chdir("/");
    if (mount("proc", "proc", "proc", 0, "") != 0) {
        perror("Could not mount proc");
    } else {
        cout << "proc successfully mounted\n";
    }
//    if (mount("sys", "sys", "sysfs", 0, "") != 0) {
//        perror("Could not mount sys");
//    }
#else
    if (mount("/proc", ALPINEDIR "proc","proc", 0, "") != 0) {
        perror("Could not mount proc");
    }
//    if (mount("/sys", ALPINEDIR "sys", "sysfs", MS_BIND, nullptr) != 0) {
//        perror("Could not mount sys");
//    }
    if (chroot(ALPINEDIR) != 0) {
        perror("chroot to " ALPINEDIR " failed");
    }
    chdir("/");
#endif
    return execvp(p->argv[0], p->argv);
}

/*!
 * \brief sets user or group mapping
 *
 * \param host_id for example 1000
 * \param container_id for example 0, to map 1000 to 0 (root)
 * \param range how many ids
 * \param filename name of the file to write
 * \return outcome of the operation
 */
static bool set_id_map(int host_id, int container_id, int range, const char *filename)
{
    ostringstream line;
    line << container_id << ' ' << host_id << ' ' << range;

    ofstream osf(filename);
    osf << line.str();
    if (osf.fail()) {
        cerr << "Could not write to " << filename << endl;
        return false;
    }
    return true;
}
