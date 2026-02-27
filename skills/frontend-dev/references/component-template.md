# Component Code Template

## List Page Component (React + TypeScript)

```typescript
import React, { useState, useEffect } from 'react';
import { Table, Button, Input, Space, Pagination, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { SearchOutlined, PlusOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { userApi } from '@/api/user';
import type { User } from '@/types/user';

const UserList: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [keyword, setKeyword] = useState('');

  // Load users
  const loadUsers = async () => {
    setLoading(true);
    try {
      const response = await userApi.getUsers({
        page,
        limit: pageSize,
        keyword,
      });
      setUsers(response.data.users);
      setTotal(response.data.total);
    } catch (error) {
      message.error('Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  // Delete user
  const handleDelete = async (id: number) => {
    try {
      await userApi.deleteUser(id);
      message.success('Deleted');
      loadUsers();
    } catch (error) {
      message.error('Delete failed');
    }
  };

  // Table columns
  const columns: ColumnsType<User> = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: 'Username',
      dataIndex: 'username',
      key: 'username',
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
    },
    {
      title: 'Mobile',
      dataIndex: 'mobile',
      key: 'mobile',
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <span style={{ color: status === 'active' ? 'green' : 'red' }}>
          {status === 'active' ? 'Active' : 'Disabled'}
        </span>
      ),
    },
    {
      title: 'Created At',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (date: string) => new Date(date).toLocaleString(),
    },
    {
      title: 'Actions',
      key: 'action',
      render: (_, record) => (
        <Space size="middle">
          <Button
            type="link"
            onClick={() => navigate(`/user/detail/${record.id}`)}
          >
            View
          </Button>
          <Button
            type="link"
            onClick={() => navigate(`/user/edit/${record.id}`)}
          >
            Edit
          </Button>
          <Button
            type="link"
            danger
            onClick={() => handleDelete(record.id)}
          >
            Delete
          </Button>
        </Space>
      ),
    },
  ];

  // Search
  const handleSearch = () => {
    setPage(1);
    loadUsers();
  };

  // Initial load
  useEffect(() => {
    loadUsers();
  }, [page, pageSize]);

  return (
    <div className="user-list">
      <div className="header">
        <h2>User List</h2>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => navigate('/user/create')}
        >
          New User
        </Button>
      </div>

      <div className="search-bar">
        <Space>
          <Input
            placeholder="Enter username or email"
            value={keyword}
            onChange={(e) => setKeyword(e.target.value)}
            onPressEnter={handleSearch}
            style={{ width: 300 }}
          />
          <Button
            type="primary"
            icon={<SearchOutlined />}
            onClick={handleSearch}
          >
            Search
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={users}
        loading={loading}
        rowKey="id"
        pagination={false}
      />

      <div className="pagination">
        <Pagination
          current={page}
          pageSize={pageSize}
          total={total}
          onChange={(page, pageSize) => {
            setPage(page);
            setPageSize(pageSize);
          }}
          showSizeChanger
          showTotal={(total) => `Total ${total}`}
        />
      </div>
    </div>
  );
};

export default UserList;
```

## Form Page Component (React + TypeScript)

```typescript
import React, { useState, useEffect } from 'react';
import {
  Form,
  Input,
  Button,
  Select,
  Upload,
  message,
  Card,
} from 'antd';
import { UploadOutlined } from '@ant-design/icons';
import { useNavigate, useParams } from 'react-router-dom';
import { userApi } from '@/api/user';
import type { User } from '@/types/user';

const { Option } = Select;

const UserForm: React.FC = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState<string>('');

  // Load user data (edit)
  useEffect(() => {
    if (id) {
      loadUserDetail(id);
    }
  }, [id]);

  const loadUserDetail = async (userId: string) => {
    try {
      const response = await userApi.getUser(Number(userId));
      const user = response.data;
      form.setFieldsValue({
        username: user.username,
        email: user.email,
        mobile: user.mobile,
        gender: user.gender,
        bio: user.bio,
      });
      setAvatarUrl(user.avatar || '');
    } catch (error) {
      message.error('Failed to load user data');
    }
  };

  // Upload avatar
  const handleUpload = async (file: File) => {
    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await userApi.uploadAvatar(formData);
      setAvatarUrl(response.data.url);
      message.success('Uploaded');
      return false;
    } catch (error) {
      message.error('Upload failed');
      return false;
    }
  };

  // Submit
  const handleSubmit = async (values: any) => {
    setLoading(true);
    try {
      if (id) {
        // Edit
        await userApi.updateUser(Number(id), {
          ...values,
          avatar: avatarUrl,
        });
        message.success('Updated');
      } else {
        // Create
        await userApi.createUser({
          ...values,
          password: values.password,
          avatar: avatarUrl,
        });
        message.success('Created');
      }
      navigate('/user/list');
    } catch (error) {
      message.error(id ? 'Update failed' : 'Create failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="user-form">
      <Card title={id ? 'Edit User' : 'New User'}>
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          autoComplete="off"
        >
          <Form.Item
            label="Username"
            name="username"
            rules={[
              { required: true, message: 'Enter username' },
              { min: 4, message: 'Min 4 characters' },
              { max: 20, message: 'Max 20 characters' },
            ]}
          >
            <Input placeholder="Enter username" />
          </Form.Item>

          <Form.Item
            label="Email"
            name="email"
            rules={[
              { required: true, message: 'Enter email' },
              { type: 'email', message: 'Enter a valid email' },
            ]}
          >
            <Input placeholder="Enter email" />
          </Form.Item>

          {!id && (
            <Form.Item
              label="Password"
              name="password"
              rules={[
                { required: true, message: 'Enter password' },
                { min: 8, message: 'Min 8 characters' },
                {
                  pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
                  message: 'Must include upper/lowercase and numbers',
                },
              ]}
            >
              <Input.Password placeholder="Enter password" />
            </Form.Item>
          )}

          <Form.Item label="Mobile" name="mobile">
            <Input placeholder="Enter mobile" />
          </Form.Item>

          <Form.Item label="Gender" name="gender">
            <Select placeholder="Select gender">
              <Option value="male">Male</Option>
              <Option value="female">Female</Option>
              <Option value="secret">Secret</Option>
            </Select>
          </Form.Item>

          <Form.Item label="Bio" name="bio">
            <Input.TextArea
              rows={4}
              placeholder="Enter bio"
              maxLength={255}
            />
          </Form.Item>

          <Form.Item label="Avatar">
            <Upload
              listType="picture"
              maxCount={1}
              beforeUpload={handleUpload}
              showUploadList={false}
            >
              <Button icon={<UploadOutlined />}>Upload Avatar</Button>
            </Upload>
            {avatarUrl && (
              <img
                src={avatarUrl}
                alt="avatar"
                style={{ width: 100, marginTop: 10 }}
              />
            )}
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit" loading={loading}>
                {id ? 'Update' : 'Create'}
              </Button>
              <Button onClick={() => navigate('/user/list')}>Cancel</Button>
            </Space>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
};

export default UserForm;
```

## List Page Component (Vue 3 + TypeScript)

```vue
<template>
  <div class="user-list">
    <div class="header">
      <h2>User List</h2>
      <el-button type="primary" @click="handleCreate">
        <el-icon><Plus /></el-icon>
        New User
      </el-button>
    </div>

    <div class="search-bar">
      <el-input
        v-model="keyword"
        placeholder="Enter username or email"
        @keyup.enter="handleSearch"
        style="width: 300px"
      >
        <template #append>
          <el-button @click="handleSearch">
            <el-icon><Search /></el-icon>
          </el-button>
        </template>
      </el-input>
    </div>

    <el-table :data="users" v-loading="loading" stripe>
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="username" label="Username" />
      <el-table-column prop="email" label="Email" />
      <el-table-column prop="mobile" label="Mobile" />
      <el-table-column label="Status">
        <template #default="{ row }">
          <el-tag :type="row.status === 'active' ? 'success' : 'danger'">
            {{ row.status === 'active' ? 'Active' : 'Disabled' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Created At">
        <template #default="{ row }">
          {{ formatDate(row.created_at) }}
        </template>
      </el-table-column>
      <el-table-column label="Actions" width="200">
        <template #default="{ row }">
          <el-button type="primary" link @click="handleView(row.id)">
            View
          </el-button>
          <el-button type="primary" link @click="handleEdit(row.id)">
            Edit
          </el-button>
          <el-button type="danger" link @click="handleDelete(row.id)">
            Delete
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination">
      <el-pagination
        v-model:current-page="page"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @current-change="loadUsers"
        @size-change="loadUsers"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Plus, Search } from '@element-plus/icons-vue';
import { userApi } from '@/api/user';
import type { User } from '@/types/user';

const router = useRouter();
const loading = ref(false);
const users = ref<User[]>([]);
const total = ref(0);
const page = ref(1);
const pageSize = ref(10);
const keyword = ref('');

// Load users
const loadUsers = async () => {
  loading.value = true;
  try {
    const response = await userApi.getUsers({
      page: page.value,
      limit: pageSize.value,
      keyword: keyword.value,
    });
    users.value = response.data.users;
    total.value = response.data.total;
  } catch (error) {
    ElMessage.error('Failed to load users');
  } finally {
    loading.value = false;
  }
};

// Delete user
const handleDelete = async (id: number) => {
  try {
    await ElMessageBox.confirm('Delete this user?', 'Confirm', {
      confirmButtonText: 'OK',
      cancelButtonText: 'Cancel',
      type: 'warning',
    });

    await userApi.deleteUser(id);
    ElMessage.success('Deleted');
    loadUsers();
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Delete failed');
    }
  }
};

// Navigation
const handleCreate = () => router.push('/user/create');
const handleView = (id: number) => router.push(`/user/detail/${id}`);
const handleEdit = (id: number) => router.push(`/user/edit/${id}`);
const handleSearch = () => {
  page.value = 1;
  loadUsers();
};

// Format date
const formatDate = (date: string) => {
  return new Date(date).toLocaleString();
};

onMounted(() => {
  loadUsers();
});
</script>

<style scoped>
.user-list {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.search-bar {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}
</style>
```
