ARG ROS_DISTRO=humble

FROM husarnet/ros:${ROS_DISTRO}-ros-core

ARG BUILD_TEST=OFF

ENV HUSARION_ROS_BUILD_TYPE=hardware

STOPSIGNAL SIGINT

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ros-humble-ros-gz \
        ros-humble-sdformat-urdf \
        ros-humble-joint-state-publisher-gui \
        ros-humble-ros2controlcli \
        ros-humble-controller-interface \
        ros-humble-hardware-interface-testing \
        ros-humble-ament-cmake-clang-format \
        ros-humble-ament-cmake-clang-tidy \
        ros-humble-controller-manager \
        ros-humble-ros2-control-test-assets \
        libignition-gazebo6-dev \
        libignition-plugin-dev \
        ros-humble-hardware-interface \
        ros-humble-control-msgs \
        ros-humble-backward-ros \
        ros-humble-generate-parameter-library \
        ros-humble-realtime-tools \
        ros-humble-joint-state-publisher \
        ros-humble-joint-state-broadcaster \
        ros-humble-moveit-ros-move-group \
        ros-humble-moveit-kinematics \
        ros-humble-moveit-planners-ompl \
        ros-humble-moveit-ros-visualization \
        ros-humble-joint-trajectory-controller \
        ros-humble-moveit-simple-controller-manager \
        ros-humble-rviz2 \
        ros-humble-xacro \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /ros2_ws
RUN git clone https://github.com/frankaemika/franka_ros2.git src/franka_ros2
RUN git clone https://github.com/husarion/husarion_ugv_ros.git husarion_ugv_ros
RUN git clone https://github.com/husarion/husarion_components_description.git src/husarion_components_description
RUN mv husarion_ugv_ros/husarion_ugv_description src/husarion_ugv_description
RUN mv husarion_ugv_ros/husarion_ugv_msgs src/husarion_ugv_msgs
RUN mv husarion_ugv_ros/husarion_ugv src/husarion_ugv
RUN rm -rf husarion_ugv_ros
COPY ./husarion_ugv_franka_manipulator_bringup src/husarion_ugv_franka_manipulator_bringup


RUN apt-get update  && \
    apt-get install -y \
        ros-dev-tools && \
    # Setup workspace
    vcs import src < src/franka_ros2/franka.repos --recursive --skip-existing && \
    rm -rf src/husarion_ugv && \
    # Install dependencies
    rosdep init && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install --from-paths src -y -i && \
    # Build
    source /opt/ros/$ROS_DISTRO/setup.bash && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=$BUILD_TEST && \
    # Size optimization
    export SUDO_FORCE_REMOVE=yes && \
    apt-get remove -y \
        ros-dev-tools && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
